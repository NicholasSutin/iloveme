/**
 * Shared HTML shell for the public pages.
 *
 * Self-contained by design: no external CSS, fonts, scripts or images. One
 * request, nothing to block, and the same visual language as the iOS app —
 * grouped background, rounded cards, muted secondary text.
 */

const FAVICON =
  "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E" +
  "%3Ctext y='26' font-size='26'%3E%F0%9F%8C%B1%3C/text%3E%3C/svg%3E";

const BASE_CSS = `
:root{
  color-scheme: light dark;
  --bg:#f6f6f4; --card:#fff; --fg:#15181d; --muted:#5c6472;
  --rule:#e5e6ea; --accent:#2c7a5b; --accent-soft:#e6f2ec;
  --radius:14px; --gutter:1.25rem;
}
@media (prefers-color-scheme: dark){
  :root{
    --bg:#101216; --card:#171a20; --fg:#e9ebee; --muted:#9aa2b1;
    --rule:#272b33; --accent:#67bd97; --accent-soft:#16241e;
  }
}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%}
body{
  margin:0; background:var(--bg); color:var(--fg);
  font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;
  -webkit-font-smoothing:antialiased;
}
.wrap{max-width:46rem;margin:0 auto;padding:0 var(--gutter)}
a{color:var(--accent);text-underline-offset:2px}
a:hover{text-decoration:underline}

header.site{padding:1.5rem 0}
header.site .wrap{display:flex;align-items:center;justify-content:space-between;gap:1rem}
.wordmark{font-weight:650;letter-spacing:-.02em;color:var(--fg);text-decoration:none;font-size:1.05rem}
.wordmark:hover{text-decoration:none}
nav.site a{font-size:.9rem;color:var(--muted);text-decoration:none}
nav.site a:hover{color:var(--fg)}

footer.site{margin-top:4rem;padding:1.75rem 0 3.5rem;border-top:1px solid var(--rule)}
footer.site .wrap{display:flex;flex-wrap:wrap;gap:.5rem 1.25rem;align-items:baseline;
  justify-content:space-between;color:var(--muted);font-size:.85rem}
footer.site p{margin:0;max-width:30rem}

h1{font-size:2.1rem;line-height:1.15;letter-spacing:-.03em;margin:0 0 .6rem}
h2{font-size:1.05rem;letter-spacing:-.01em;margin:2.5rem 0 .75rem}
p{margin:0 0 1rem}
ul{padding-left:1.15rem;margin:0 0 1rem}
li{margin:.3rem 0}
code{font-size:.9em;background:color-mix(in srgb,var(--fg) 8%,transparent);
  padding:.1em .35em;border-radius:5px}
@media (max-width:30rem){ h1{font-size:1.75rem} }
`;

export interface PageOptions {
  title: string;
  description: string;
  body: string;
  css?: string;
}

function escapeAttr(value: string): string {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/"/g, "&quot;");
}

export function shell({ title, description, body, css = "" }: PageOptions): string {
  const safeTitle = escapeAttr(title);
  const safeDescription = escapeAttr(description);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${safeTitle}</title>
<meta name="description" content="${safeDescription}">
<meta property="og:title" content="${safeTitle}">
<meta property="og:description" content="${safeDescription}">
<meta property="og:type" content="website">
<link rel="icon" href="${FAVICON}">
<style>${BASE_CSS}${css}</style>
</head>
<body>
<header class="site"><div class="wrap">
  <a class="wordmark" href="/">ILoveMe</a>
  <nav class="site"><a href="/privacy">Privacy</a></nav>
</div></header>
${body}
<footer class="site"><div class="wrap">
  <p>An independent personal project. Not affiliated with, endorsed by, or sponsored by
  Apple, GitHub, Notion or Pinterest.</p>
  <a href="/privacy">Privacy&nbsp;policy</a>
</div></footer>
</body>
</html>`;
}
