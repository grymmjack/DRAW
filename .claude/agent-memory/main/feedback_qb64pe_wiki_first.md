---
name: qb64pe-wiki-first
description: "Always check qb64phoenix.com wiki directly for keyword syntax, not the MCP get_qb64pe_page tool — the MCP's scraped content drops critical syntax/parameter details"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 74038101-3a17-49bd-acf2-1a71a21ba671
---

The `mcp__qb64pe__get_qb64pe_page` and `mcp__qb64pe__lookup_qb64pe_keyword` tools return incomplete content. They scrape the wiki but lose the **Syntax**, **Parameters**, and **Description** sections — exactly the parts you need to use a keyword correctly. Headings come through but the body content under them is empty.

**How to apply:** for any QB64-PE keyword question (especially `_SETALPHA`, `_MAPTRIANGLE`, `_PUTIMAGE`, `_COPYIMAGE`, `_DONTBLEND` and other graphics primitives where syntax variants matter), `WebFetch` the wiki URL directly instead. Pattern:
- Page URL: `https://qb64phoenix.com/qb64wiki/index.php/<KEYWORD_WITHOUT_UNDERSCORE>` (e.g. `SETALPHA`, `MAPTRIANGLE`)
- Or with underscore: `https://qb64phoenix.com/qb64wiki/index.php/_<KEYWORD>` (some entries vary)
- Ask `WebFetch` for the exact syntax forms, parameters, edge cases

**Why:** burned ~1 hour on `_SETALPHA 255, , img` (empty middle param) because the MCP said it could mean "all pixels." It does not — that's invalid syntax that silently does nothing. The real "all pixels" form is `_SETALPHA 255, img` (no middle parameter at all). The wiki shows this clearly; the MCP scrape doesn't.

Related: see [[reference_qb64pe_sandbox_limitation]] for compile workflow.
