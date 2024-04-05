local Src = {}

Src.new = function(_)
  local self = setmetatable({}, {
    __index = Src,
  })
  return self
end

---Return whether this source is available in the current context or not (optional).
---@return boolean
function Src:is_available()
  local mode = vim.api.nvim_get_mode().mode:sub(1, 1)
  return mode == "c" and vim.fn.getcmdtype() == ":"
end

---Return the debug name of this source (optional).
---@return string
function Src:get_debug_name()
  return "fzf-lua"
end

---Invoke completion (required).
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function Src:complete(params, callback)
  if not params.context.cursor_before_line:match("FzfLua") then
    return callback()
  end
  -- _G.dump("complete", params)
  return callback(require("fzf-lua.cmd")._candidates(params.context.cursor_before_line, true))
end

---@param completion_item lsp.CompletionItem
---@return lsp.MarkupContent?
function Src:_get_documentation(completion_item)
  -- Only attempt to load from file once, if failed we ditch the docs
  if Src._options == nil then
    local path = require "fzf-lua.path"
    local utils = require "fzf-lua.utils"
    local options_md = path.join({ vim.g.fzf_lua_root, "OPTIONS.md" })
    local lines = vim.split(utils.read_file(options_md), "\n")
    if not vim.tbl_isempty(lines) then
      Src._options = {}
      local section
      for _, l in ipairs(lines) do
        if l:match("^#") or l:match("<!%-%-") then
          -- Match markdown atx header levels 3-4 only
          section = l:match("^####?%s+(.*)")
          if section then
            -- Use only the non-spaced rightmost part of the line
            -- "Opts: files" will be translated to "files" section
            section = section:match("[^%s]+$")
            Src._options[section] = {}
            goto continue
          end
        end
        if section then
          table.insert(Src._options[section], l)
        end
        ::continue::
      end
      Src._options = vim.tbl_map(function(v)
        while rawget(v, 1) == "" do
          table.remove(v, 1)
        end
        while rawget(v, #v) == "" do
          table.remove(v)
        end
        return table.concat(v, "\n")
      end, Src._options)
    end
  end
  if not Src._options then return end
  local markdown = Src._options[completion_item.label]
  if not markdown and completion_item.data and completion_item.data.cmd then
    -- didn't find anything from global options, search provider specific
    -- e.g. for "cwd_prompt" option we search the dict for "files.cwd_prompt"
    markdown = Src._options[completion_item.data.cmd .. "." .. completion_item.label]
  end
  return markdown and { kind = "markdown", value = markdown } or nil
end

---Resolve completion item (optional).
-- This is called right before the completion is about to be displayed.
---Useful for setting the text shown in the documentation window (`completion_item.documentation`).
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function Src:resolve(completion_item, callback)
  completion_item.documentation = self:_get_documentation(completion_item)
  callback(completion_item)
end

function Src._register_cmdline()
  local ok, cmp = pcall(require, "cmp")
  if not ok then return end
  cmp.register_source("FzfLua", Src)
  local cmdline_cfg = require("cmp.config").cmdline
  local has_fzf_lua = false
  for _, s in ipairs(cmdline_cfg[":"].sources or {}) do
    if s.name == "FzfLua" then
      has_fzf_lua = true
    end
  end
  if not has_fzf_lua then
    if cmdline_cfg[":"] then
      table.insert(cmdline_cfg[":"].sources or {}, {
        group_index = 1,
        name = "FzfLua",
        option = {}
      })
    end
  end
end

return Src
