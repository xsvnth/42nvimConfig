local types = {
  int = true,
  char = true,
  long = true,
  short = true,
  unsigned = true,
  signed = true,
  float = true,
  double = true,
  size_t = true,
  ssize_t = true,
  bool = true,
  struct = true,
  enum = true,
}

local function is_type(w)
  return types[w] or w:match("^t_[%w_]+$") or w:match("^u?int%d+_t$")
end

local function split_top(s)
  local parts, depth, cur, q, i = {}, 0, "", nil, 1
  while i <= #s do
    local ch = s:sub(i, i)
    if q then
      cur = cur .. ch
      if ch == "\\" then
        cur = cur .. s:sub(i + 1, i + 1)
        i = i + 1
      elseif ch == q then
        q = nil
      end
    elseif ch == '"' or ch == "'" then
      q = ch
      cur = cur .. ch
    elseif ch:match("[%(%[{]") then
      depth = depth + 1
      cur = cur .. ch
    elseif ch:match("[%)%]}]") then
      depth = depth - 1
      cur = cur .. ch
    elseif ch == "," and depth == 0 then
      parts[#parts + 1] = cur
      cur = ""
    else
      cur = cur .. ch
    end
    i = i + 1
  end
  parts[#parts + 1] = cur
  return parts
end

local function parse_decl(body)
  local typ, rest = "", body
  while true do
    local w, r = rest:match("^%s*([%a_][%w_]*)(.*)$")
    if not w then
      break
    end
    if w == "struct" or w == "enum" then
      local w2, r2 = r:match("^%s+([%a_][%w_]*)(.*)$")
      if not w2 then
        return nil
      end
      typ = typ .. w .. " " .. w2 .. " "
      rest = r2
    elseif is_type(w) or w == "const" or w == "static" then
      typ = typ .. w .. " "
      rest = r
    else
      break
    end
  end
  if typ == "" then
    return nil
  end
  return vim.trim(typ), vim.trim(rest)
end

local function brace_delta(l)
  local s = l:gsub('"[^"]*"', ""):gsub("'[^']*'", "")
  local d = 0
  for c in s:gmatch("[{}]") do
    d = d + (c == "{" and 1 or -1)
  end
  return d
end

local function fix(lines)
  local pre, d0 = {}, 0
  for _, l in ipairs(lines) do
    local sig = l:match("^([%a_][^;{}]*%))%s*{%s*$")
    if d0 == 0 and sig then
      pre[#pre + 1] = sig
      pre[#pre + 1] = "{"
    else
      pre[#pre + 1] = l
    end
    d0 = d0 + brace_delta(l)
  end
  lines = pre
  local out, depth, i, n = {}, 0, 1, #lines
  while i <= n do
    local l = lines[i]
    local ind, body = l:match("^(%s*)(.-);%s*$")
    local split = false
    if
      depth >= 1
      and body
      and (
        body:match("^[%a_][%w_%.%-%>%[%]]*%s*[%+%-%*/]?=[^=]")
        or body:match("^[%a_][%w_%.%-%>%[%]]*%s*%+%+")
        or body:match("^[%a_][%w_%.%-%>%[%]]*%s*%-%-")
      )
    then
      local parts = split_top(body)
      if #parts > 1 then
        local wrap = false
        if #ind > 0 then
          for k = #out, 1, -1 do
            local o = out[k]
            if o:match("%S") and #o:match("^(%s*)") < #ind then
              wrap = o:match("^%s*if%s*%(")
                or o:match("^%s*else if%s*%(")
                or o:match("^%s*while%s*%(")
                or o:match("^%s*for%s*%(")
                or o:match("^%s*else%s*$")
              break
            end
          end
        end
        local bi = ind:sub(1, #ind - 1)
        if wrap then
          out[#out + 1] = bi .. "{"
        end
        for _, p in ipairs(parts) do
          out[#out + 1] = ind .. vim.trim(p) .. ";"
        end
        if wrap then
          out[#out + 1] = bi .. "}"
        end
        split = true
      end
    end
    if not split then
      out[#out + 1] = l
    end

    local was = depth
    depth = depth + brace_delta(l)

    if was == 0 and depth == 1 and l:match("^{%s*$") and (out[#out - 1] or ""):match("%)%s*$") then
      local decls, assigns, j, last, stop = {}, {}, i + 1, i, false
      while j <= n and not stop do
        local s = lines[j]
        if s:match("^%s*$") then
          j = j + 1
        else
          local ind2, b2 = s:match("^(%s*)(.-);%s*$")
          local typ, rest
          if b2 then
            typ, rest = parse_decl(b2)
          end
          if not typ or rest == "" then
            break
          end
          local d, a = {}, {}
          for _, p in ipairs(split_top(rest)) do
            p = vim.trim(p)
            local name, init = p:match("^(.-)%s*=%s*(.+)$")
            if init and (init:sub(1, 1) == "{" or name:find("%[")) then
              stop = true
              break
            end
            if init then
              d[#d + 1] = ind2 .. typ .. " " .. name .. ";"
              a[#a + 1] = ind2 .. (name:gsub("^[%s%*]+", "")) .. " = " .. init .. ";"
            else
              d[#d + 1] = ind2 .. typ .. " " .. p .. ";"
            end
          end
          if not stop then
            vim.list_extend(decls, d)
            vim.list_extend(assigns, a)
            last = j
            j = j + 1
          end
        end
      end
      if #decls > 0 then
        vim.list_extend(out, decls)
        out[#out + 1] = ""
        vim.list_extend(out, assigns)
        i = last
      end
    end
    i = i + 1
  end
  return out
end

local function spaces(lines)
  for k, l in ipairs(lines) do
    if not l:find('"') and not l:find("^%s*/%*") then
      for _ = 1, 2 do
        l = l:gsub("(%S)%s*&&%s*(%S)", "%1 && %2")
        l = l:gsub("(%S)%s*||%s*(%S)", "%1 || %2")
      end
      lines[k] = l
    end
  end
  return lines
end

local function mask(text)
  local strs, out, i, n = {}, {}, 1, #text
  while i <= n do
    local ch = text:sub(i, i)
    local bol = (i == 1 or text:sub(i - 1, i - 1) == "\n")
    if ch == "#" and bol then
      local e = text:find("\n", i, true) or (n + 1)
      out[#out + 1] = text:sub(i, e - 1)
      i = e
    elseif ch == '"' or ch == "'" then
      local j = i + 1
      while j <= n do
        local c = text:sub(j, j)
        if c == "\\" then
          j = j + 2
        elseif c == ch then
          break
        elseif c == "\n" then
          j = nil
          break
        else
          j = j + 1
        end
      end
      if j and j <= n then
        if ch == '"' then
          strs[#strs + 1] = text:sub(i, j)
          out[#out + 1] = "__S" .. #strs .. "__"
        else
          out[#out + 1] = text:sub(i, j)
        end
        i = j + 1
      else
        out[#out + 1] = ch
        i = i + 1
      end
    else
      out[#out + 1] = ch
      i = i + 1
    end
  end
  return table.concat(out), strs
end

local function vwidth(s, strs)
  s = s:gsub("__S(%d+)__", function(k)
    return strs[tonumber(k)]
  end)
  local w = 0
  for ch in s:gmatch(".") do
    if ch == "\t" then
      w = w + 4 - (w % 4)
    else
      w = w + 1
    end
  end
  return w
end

local function pdelta(l)
  l = l:gsub("'\\?.'", "")
  local _, o = l:gsub("%(", "")
  local _, c = l:gsub("%)", "")
  return o - c
end

local function split_ops(s, op)
  local parts, depth, start, i, n = {}, 0, 1, 1, #s
  while i <= n do
    local lit = s:match("^'\\?.'", i)
    if lit then
      i = i + #lit
    else
      local c = s:sub(i, i)
      if c == "(" or c == "[" then
        depth = depth + 1
      elseif c == ")" or c == "]" then
        depth = depth - 1
      elseif depth == 0 and s:sub(i, i + #op - 1) == op then
        parts[#parts + 1] = s:sub(start, i - 1)
        i = i + #op - 1
        start = i + 1
      end
      i = i + 1
    end
  end
  parts[#parts + 1] = s:sub(start)
  return parts
end

local function group_cond(s)
  local o = s:find("(", 1, true)
  if not o then
    return s
  end
  local depth, i, n, close = 0, o, #s, nil
  while i <= n do
    local lit = s:match("^'\\?.'", i)
    if lit then
      i = i + #lit
    else
      local c = s:sub(i, i)
      if c == "(" then
        depth = depth + 1
      elseif c == ")" then
        depth = depth - 1
        if depth == 0 then
          close = i
          break
        end
      end
      i = i + 1
    end
  end
  if not close then
    return s
  end
  local ors = split_ops(s:sub(o + 1, close - 1), " || ")
  if #ors < 2 then
    return s
  end
  local changed = false
  for k, g in ipairs(ors) do
    if #split_ops(g, " && ") > 1 then
      ors[k] = "(" .. g .. ")"
      changed = true
    end
  end
  if not changed then
    return s
  end
  return s:sub(1, o) .. table.concat(ors, " || ") .. s:sub(close)
end

local function wrap_conds(lines, strs)
  local out, i, n = {}, 1, #lines
  while i <= n do
    local l = lines[i]
    local ind = l:match("^(\t*)if%s*%(") or l:match("^(\t*)else if%s*%(") or l:match("^(\t*)while%s*%(")
    if ind then
      local depth, j, parts = pdelta(l), i, { l }
      while depth > 0 and j < n do
        j = j + 1
        parts[#parts + 1] = lines[j]
        depth = depth + pdelta(lines[j])
      end
      local joined = vim.trim(parts[1])
      for k = 2, #parts do
        joined = joined .. " " .. vim.trim(parts[k])
      end
      joined = joined:gsub("([%(%[]) ", "%1"):gsub(" ([%)%]])", "%1")
      local grouped = group_cond(joined)

      local segs, pos = {}, 1
      while true do
        local a1 = grouped:find(" || ", pos + 1, true)
        local a2 = grouped:find(" && ", pos + 1, true)
        local a = (a1 and a2) and math.min(a1, a2) or a1 or a2
        if not a then
          break
        end
        segs[#segs + 1] = grouped:sub(pos, a - 1)
        pos = a + 1
      end
      segs[#segs + 1] = grouped:sub(pos)

      if #segs > 1 then
        local cont = ind .. "\t"
        local cur = ind .. segs[1]
        for k = 2, #segs do
          if vwidth(cur .. " " .. segs[k], strs) > 80 then
            out[#out + 1] = cur
            cur = cont .. segs[k]
          else
            cur = cur .. " " .. segs[k]
          end
        end
        out[#out + 1] = cur
      else
        vim.list_extend(out, parts)
      end
      i = j
    else
      out[#out + 1] = l
    end
    i = i + 1
  end
  return out
end

return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      c = { "norm42" },
      h = { "norm42" },
    },
    formatters = {
      norm42 = {
        format = function(self, ctx, lines, callback)
          local text, strs = mask(table.concat(lines, "\n"))
          local l2 = spaces(fix(vim.split(text, "\n", { plain = true })))
          vim.system(
            { vim.fn.expand("~/.local/bin/c_formatter_42") },
            { stdin = table.concat(l2, "\n") .. "\n", text = true },
            function(res)
              vim.schedule(function()
                if res.code ~= 0 then
                  return callback("c_formatter_42 failed")
                end
                local ol = vim.split((res.stdout:gsub("\n$", "")), "\n", { plain = true })
                ol = wrap_conds(ol, strs)
                local o = table.concat(ol, "\n"):gsub("__S(%d+)__", function(k)
                  return strs[tonumber(k)]
                end)
                callback(nil, vim.split(o, "\n", { plain = true }))
              end)
            end
          )
        end,
      },
    },
    format_on_save = {
      timeout_ms = 2000,
      lsp_format = "never",
    },
  },
}
