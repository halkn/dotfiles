# Splits .tool_input.command into simple commands and prints one per line, its words joined
# by U+001F, for the hooks that judge a program by its arguments.
#
# Quotes are honoured and removed, so a quoted `(`, `|` or space stays inside its word.
# Command substitutions, backquotes, subshells and process substitutions become commands of
# their own. Redirections are dropped along with their targets. A newline inside a word
# becomes a space so that each command stays on one line. Leading assignments and wrapper
# commands (with their options and a numeric argument such as a timeout) are dropped, and the
# program is reduced to its basename.

def flush_word:
  if .w == null then .
  elif .drop then .w = null | .drop = false
  else .cur += [.w] | .w = null
  end;

def flush_cmd:
  flush_word
  | .redir = false
  | if (.cur | length) > 0 then .cmds += [.cur] | .cur = [] else . end;

# A word that starts right after a redirection operator is its target.
def start_word:
  if .redir and .w == null then .redir = false | .drop = true else . end
  | .w = (.w // "");

# A substitution is split out as its own command; the command around it is set aside and
# resumed afterwards, with the substitution standing in its word as `$()`.
def open_sub($k):
  .stack += [{k: $k, q: .q, cur: .cur, w: .w, drop: .drop}]
  | .cur = []
  | .w = null
  | .q = null
  | .drop = false
  | .redir = false;

def close_sub:
  flush_cmd
  | .stack[-1] as $s
  | .stack |= .[:-1]
  | .q = $s.q
  | .cur = $s.cur
  | .drop = $s.drop
  | .w = ($s.w // "") + "$()";

def step($c):
  if .comment then
    if $c == "\n" then .comment = false | flush_cmd else . end
  elif .esc then
    .esc = false
    | if .q == null and $c == "\n" then .
      elif .q == "\"" and ($c | test("[\"\\\\$`\n]") | not) then start_word | .w += "\\" + $c
      else start_word | .w += $c
      end
  elif .q == "'" then
    if $c == "'" then .q = null else .w += $c end
  elif $c == "\\" then .esc = true
  elif $c == "`" then
    if (.stack | length) > 0 and .stack[-1].k == "`" then close_sub else open_sub("`") end
  elif $c == "(" and ((.w // "") | endswith("$")) then
    .w |= .[:-1] | (if .w == "" then .w = null else . end) | open_sub("(")
  elif .q == "\"" then
    if $c == "\"" then .q = null else .w += $c end
  elif $c == "(" and .redir and .w == null then
    .redir = false | open_sub("(")
  elif $c == ")" and (.stack | length) > 0 and .stack[-1].k == "(" then close_sub
  elif $c == "'" or $c == "\"" then start_word | .q = $c
  elif $c == "#" and .w == null then .comment = true
  elif $c == ">" or $c == "<" then
    (if (.w // "") | test("^[0-9]+$") then .w = null else . end)
    | flush_word
    | .redir = true
  elif ($c == "&" or $c == "|") and .redir and .w == null then .
  elif $c | test("[|&;()\n]") then flush_cmd
  elif $c | test("[ \t]") then flush_word
  else start_word | .w += $c
  end;

def wrappers:
  ["sudo", "doas", "env", "nohup", "time", "exec", "command", "builtin", "noglob", "watch",
    "xargs", "stdbuf", "nice", "ionice", "setsid", "timeout"];

def strip_prefix:
  if length == 0 then .
  elif .[0] | test("^[A-Za-z_][A-Za-z0-9_]*=") then .[1:] | strip_prefix
  elif .[0] as $w | wrappers | index($w) then
    .[1:]
    | until(length == 0 or (.[0] | test("^-|^[0-9.]+[smhd]?$") | not); .[1:])
    | strip_prefix
  else .
  end;

.tool_input.command // ""
| reduce (split("")[]) as $c (
    {cmds: [], cur: [], w: null, q: null, esc: false, redir: false, drop: false,
      comment: false, stack: []};
    step($c))
| flush_cmd
| .cmds[]
| map(gsub("\n"; " "))
| strip_prefix
| select(length > 0)
| .[0] |= sub(".*/"; "")
| join("\u001f")
