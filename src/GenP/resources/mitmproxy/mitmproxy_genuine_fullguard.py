# mitmproxy_genuine_fullguard.py
"""
WARNING: Adobe frequently updates their genuine popup detection URLs and telemetry endpoints.
This script uses best-effort pattern matching but may require updates if popups reappear.
Please monitor Mitmproxy logs regularly and update the regexes or blocklists accordingly.
"""
from mitmproxy import http, ctx
from pathlib import Path
import re, datetime, sys

LOCAL_HTML_PATH = Path(r"C:\adobe_fixes\genuine_ok_auto_close.html")
ENABLE_BODY_INSPECTION = True
PRINT_TO_CONSOLE = True
USE_COLOR = True

_ngl_oobe_completed = False

EMPTY_JS  = b"// neutralised by mitmproxy - genuine script stub\n"
SAFE_JSON = b'{"status":"ok"}'

LICENSED_PROFILE_JSON = b'{"status":"ok","user_profile":{},"relationship_profile":{"relationship_status":"SUBSCRIBED","entitlements":[{"id":"PremierePro1","product_id":"PremierePro1","status":"ACTIVE","type":"SUBSCRIPTION"}]}}'

BUILTIN_FAKE_HTML = """<!doctype html><html><head><meta charset='utf-8'><title>已拦截</title>
<script>(async()=>{try{if('serviceWorker' in navigator){const regs=await navigator.serviceWorker.getRegistrations();for(const r of regs)try{await r.unregister()}catch(e){} }}catch(e){}try{window.close()}catch(e){}try{location.replace('about:blank')}catch(e){}})();</script>
</head><body>Adobe 弹窗已拦截</body></html>""".encode("utf-8")

LOCAL_HTML_BYTES = None
if LOCAL_HTML_PATH.exists():
    try:
        LOCAL_HTML_BYTES = LOCAL_HTML_PATH.read_bytes()
        if PRINT_TO_CONSOLE:
            print(f"[本地页面] 已从 {LOCAL_HTML_PATH} 加载 {len(LOCAL_HTML_BYTES)} 字节")
    except Exception as e:
        LOCAL_HTML_BYTES = None
        if PRINT_TO_CONSOLE:
            print(f"[本地页面] 加载失败：{e}")
if LOCAL_HTML_BYTES is None:
    LOCAL_HTML_BYTES = BUILTIN_FAKE_HTML
    if PRINT_TO_CONSOLE:
        print("[本地页面] 正在使用内置备用页面")

STRICT_POPUP_RE = re.compile(
    r"/genuine/.*\bic-[^/]*-cx(?:\d+)?(?:-nc)?(?:\.html)?(?:\?.*)?$",
    re.IGNORECASE,
)
GENERIC_POPUP_RE = re.compile(r"(?:/genuine/|/ic[-_]|[-_]nc\.html)", re.IGNORECASE)
EXTERNAL_SCRIPT_GENUINE_RE = re.compile(r"(genuine|adobe_genuine|adobegenuine)", re.IGNORECASE)

MODAL_TAG_RE = re.compile(
    r'<(?P<tag>div|section|aside|dialog)\b[^>]*(?:class|id)\s*=\s*["\'][^"\']*(?:genuine|adobe[_-]?genuine)[^"\']*["\'][^>]*>.*?</(?P=tag)>',
    re.IGNORECASE | re.DOTALL,
)
INLINE_SCRIPT_GENUINE_RE = re.compile(
    r'<script\b[^>]*>.*?(?:adobe genuine|adobe_genuine|genuine software|showGenuine|openGenuineModal).*?</script>',
    re.IGNORECASE | re.DOTALL,
)
INLINE_CALLS_RE = re.compile(
    r'\b(showGenuine|openGenuineModal|displayGenuineModal)\s*\([^;]{0,400}\);?',
    re.IGNORECASE | re.DOTALL,
)

NGL_TRIAL_PATH_RE = re.compile(
    r"(?:starttrial|buyflow|trial[-_]required|trialrequired|pes[-_]required|pesrequired|oobe|workflowid=starttrial|/ngl/trial)",
    re.IGNORECASE,
)
LCS_COPS_PROFILE_RE = re.compile(
    r"/desktops/access_profile/",
    re.IGNORECASE,
)

ANSI = {
    "reset":  "\x1b[0m",
    "green":  "\x1b[32m",
    "yellow": "\x1b[33m",
    "red":    "\x1b[31m",
    "cyan":   "\x1b[36m",
}

STATUS_LABELS = {
    "STRICT_POPUP_MATCH": "匹配到精确弹窗规则",
    "STRICT_POPUP_REPLACED_LOCAL": "已用本地页面替换精确匹配的弹窗",
    "GENERIC_POPUP_SEEN": "发现常规弹窗",
    "GENERIC_POPUP_REPLACED_LOCAL": "已用本地页面替换常规弹窗",
    "EXTERNAL_SCRIPT_GENUINE_NEUTRALISED": "已停用外部正版验证脚本",
    "EXTERNAL_JSON_GENUINE_NEUTRALISED": "已替换外部正版验证数据",
    "MODAL_STRIPPED": "已移除正版验证弹窗",
    "NGL_STARTTRIAL_KILLED": "已终止 NGL 试用请求",
    "NGL_OOBE_STUBBED": "已替换 NGL 初始设置响应",
    "LCS_COPS_POST_OOBE_LICENSED": "已返回初始设置后的授权状态",
    "NGL_STARTTRIAL_REDIRECT": "已重定向 NGL 试用请求",
    "NGL_WORKFLOW_JS_NEUTRALISED": "已停用 NGL 工作流脚本",
    "NGL_WORKFLOW_CSS_NEUTRALISED": "已停用 NGL 工作流样式",
    "NGL_WORKFLOW_JSON_NEUTRALISED": "已替换 NGL 工作流数据",
    "NGL_WORKFLOW_HTML_BLOCKED": "已拦截 NGL 工作流页面",
    "SSTATS_TELEMETRY_STUBBED": "已替换 sstats 遥测响应",
    "ADOBESTATS_STUB": "已替换 adobestats 遥测响应",
}

def _now_iso():
    return datetime.datetime.utcnow().isoformat() + "Z"

def _color_text(color_name: str, text: str) -> str:
    if USE_COLOR and color_name in ANSI:
        return f"{ANSI[color_name]}{text}{ANSI['reset']}"
    return text

def _console(kind: str, host: str, url: str) -> None:
    if not PRINT_TO_CONSOLE:
        return
    ts   = _now_iso()
    k = kind.upper()
    display_kind = STATUS_LABELS.get(k, kind)
    if k.startswith("STRICT_POPUP_SKIPPED_UPSTREAM_"):
        status = k.removeprefix("STRICT_POPUP_SKIPPED_UPSTREAM_")
        display_kind = f"精确匹配的弹窗未替换，上游状态：{'无响应' if status == 'NO_RESPONSE' else status}"
    elif k.startswith("GENERIC_POPUP_SKIPPED_UPSTREAM_"):
        status = k.removeprefix("GENERIC_POPUP_SKIPPED_UPSTREAM_")
        display_kind = f"常规弹窗未替换，上游状态：{'无响应' if status == 'NO_RESPONSE' else status}"
    line = f"{ts}  {display_kind}  {host}  {url}"
    if k.endswith("_REPLACED") or k.endswith("_REPLACED_LOCAL") or k.startswith("STRICT_POPUP"):
        c = "green"
    elif "SKIPPED_UPSTREAM_404" in k:
        c = "yellow"
    elif "NEUTRALISED" in k or "ADOBESTATS" in k or "MODAL_STRIPPED" in k or "NGL_" in k or "LCS_" in k:
        c = "cyan"
    else:
        c = "red"
    print(_color_text(c, line))

def _no_cache_headers(extra=None):
    h = {"Cache-Control": "no-store, no-cache, must-revalidate, max-age=0",
         "Pragma": "no-cache", "Expires": "0"}
    if extra:
        h.update(extra)
    return h

def _serve_local_html(flow: http.HTTPFlow, reason: str) -> bool:
    headers = _no_cache_headers({"Content-Type": "text/html; charset=UTF-8"})
    flow.response = http.Response.make(200, LOCAL_HTML_BYTES, headers)
    _console(reason, (flow.request.host or ""), flow.request.pretty_url)
    return True

def _neutralize_js(flow: http.HTTPFlow, reason: str) -> bool:
    headers = _no_cache_headers({"Content-Type": "application/javascript; charset=UTF-8"})
    flow.response = http.Response.make(200, EMPTY_JS, headers)
    _console(reason, (flow.request.host or ""), flow.request.pretty_url)
    return True

def _neutralize_json(flow: http.HTTPFlow, reason: str, body: bytes = SAFE_JSON) -> bool:
    headers = _no_cache_headers({"Content-Type": "application/json; charset=UTF-8"})
    flow.response = http.Response.make(200, body, headers)
    _console(reason, (flow.request.host or ""), flow.request.pretty_url)
    return True

def _neutralize_css(flow: http.HTTPFlow, reason: str) -> bool:
    headers = _no_cache_headers({"Content-Type": "text/css; charset=UTF-8"})
    flow.response = http.Response.make(200, b"/* neutralised */", headers)
    _console(reason, (flow.request.host or ""), flow.request.pretty_url)
    return True

def load(l):
    try:
        sys.stdout.reconfigure(line_buffering=True)
    except Exception:
        pass
    try:
        if hasattr(ctx, "options"):
            ctx.options.connection_strategy = "lazy"
            ctx.options.quiet = True
            ctx.options.console_eventlog_verbosity = "error"
            ctx.options.termlog_verbosity = "error"
    except Exception:
        pass

def request(flow: http.HTTPFlow) -> None:
    try:
        host = (flow.request.host or "").lower()
        url  = (flow.request.pretty_url or "").lower()
        if "workflow.licenses.adobe.com" in host and "starttrial" in url:
            flow.kill()
            _console("NGL_STARTTRIAL_KILLED", host, url)
    except Exception:
        return

def response(flow: http.HTTPFlow) -> None:
    global _ngl_oobe_completed
    try:
        host = (flow.request.host or "").lower()
        path = (flow.request.path or "").lower()
        url  = (flow.request.pretty_url or "").lower()

        if STRICT_POPUP_RE.search(path):
            _console("STRICT_POPUP_MATCH", host, url)
            if flow.response and flow.response.status_code == 200:
                _serve_local_html(flow, "STRICT_POPUP_REPLACED_LOCAL")
            else:
                status = flow.response.status_code if flow.response else "no_response"
                _console(f"STRICT_POPUP_SKIPPED_UPSTREAM_{status}", host, url)
            return

        if "adobe" not in host and "adobestats.io" not in host and "sstats.adobe.com" not in host and "oobe.adobe.com" not in host:
            return

        if host == "oobe.adobe.com" or host.endswith(".oobe.adobe.com"):
            _ngl_oobe_completed = True
            headers = _no_cache_headers({"Content-Type": "text/html; charset=UTF-8"})
            flow.response = http.Response.make(200, b"<!doctype html><html><head></head><body></body></html>", headers)
            _console("NGL_OOBE_STUBBED", host, flow.request.pretty_url)
            return

        if "lcs-cops.adobe.io" in host and LCS_COPS_PROFILE_RE.search(path):
            if _ngl_oobe_completed:
                _ngl_oobe_completed = False
                _neutralize_json(flow, "LCS_COPS_POST_OOBE_LICENSED", LICENSED_PROFILE_JSON)
                return

        if "workflow.licenses.adobe.com" in host:
            if NGL_TRIAL_PATH_RE.search(path) or NGL_TRIAL_PATH_RE.search(url):
                try:
                    import urllib.parse
                    params = urllib.parse.parse_qs(urllib.parse.urlparse(flow.request.pretty_url).query)
                    intercept = params.get("intercepturl", ["https://oobe.adobe.com/"])[0]
                except Exception:
                    intercept = "https://oobe.adobe.com/"
                redirect_html = (
                    b"<!doctype html><html><head><meta charset='utf-8'>"
                    b"<script>location.replace('" + intercept.encode() + b"');</script>"
                    b"</head><body></body></html>"
                )
                headers = _no_cache_headers({"Content-Type": "text/html; charset=UTF-8"})
                flow.response = http.Response.make(200, redirect_html, headers)
                _console("NGL_STARTTRIAL_REDIRECT", host, flow.request.pretty_url)
                return
            ctype = (flow.response.headers.get("content-type", "")
                     if flow.response and flow.response.headers else "").lower()
            if path.endswith(".js") or "javascript" in ctype:
                _neutralize_js(flow, "NGL_WORKFLOW_JS_NEUTRALISED")
                return
            if path.endswith(".css") or "text/css" in ctype:
                _neutralize_css(flow, "NGL_WORKFLOW_CSS_NEUTRALISED")
                return
            if path.endswith(".json") or "json" in ctype:
                _neutralize_json(flow, "NGL_WORKFLOW_JSON_NEUTRALISED")
                return
            if "text/html" in ctype:
                _serve_local_html(flow, "NGL_WORKFLOW_HTML_BLOCKED")
                return


        if GENERIC_POPUP_RE.search(path):
            _console("GENERIC_POPUP_SEEN", host, url)
            if flow.response and flow.response.status_code == 200:
                _serve_local_html(flow, "GENERIC_POPUP_REPLACED_LOCAL")
            else:
                status = flow.response.status_code if flow.response else "no_response"
                _console(f"GENERIC_POPUP_SKIPPED_UPSTREAM_{status}", host, url)
            return

        if EXTERNAL_SCRIPT_GENUINE_RE.search(path):
            ctype = (flow.response.headers.get("content-type", "")
                     if flow.response and flow.response.headers else "").lower()
            if path.endswith(".js") or "javascript" in ctype:
                _neutralize_js(flow, "EXTERNAL_SCRIPT_GENUINE_NEUTRALISED")
                return
            if path.endswith(".json") or "json" in ctype:
                _neutralize_json(flow, "EXTERNAL_JSON_GENUINE_NEUTRALISED")
                return

        if ENABLE_BODY_INSPECTION and flow.response and flow.response.headers:
            ctype = (flow.response.headers.get("content-type", "") or "").lower()
            if "text/html" in ctype:
                text    = flow.response.get_text(strict=False)
                lowered = text.lower()
                if any(tok in lowered for tok in ("genuine", "adobe_genuine", "/genuine/")):
                    original_text = text
                    newtext = MODAL_TAG_RE.sub("", original_text)
                    newtext = INLINE_SCRIPT_GENUINE_RE.sub("", newtext)
                    newtext = INLINE_CALLS_RE.sub("", newtext)
                    if newtext != original_text:
                        headers = _no_cache_headers({"Content-Type": "text/html; charset=UTF-8"})
                        flow.response = http.Response.make(
                            flow.response.status_code or 200,
                            newtext.encode("utf-8"),
                            headers,
                        )
                        _console("MODAL_STRIPPED", host, url)
                        return

        if "sstats.adobe.com" in host:
            flow.response = http.Response.make(200,
                b"GIF89a\x01\x00\x01\x00\x00\xff\x00,\x00\x00\x00\x00\x01\x00\x01\x00\x00\x02\x00;",
                {"Content-Type": "image/gif"})
            _console("SSTATS_TELEMETRY_STUBBED", host, url)
            return

        if host == "adobestats.io" or host.endswith(".adobestats.io"):
            _neutralize_json(flow, "ADOBESTATS_STUB")
            return

    except Exception:
        return
