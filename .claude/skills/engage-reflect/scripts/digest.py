"""Condense Claude Code session transcripts into readable digests for Reflect.

Usage:
  python3 -I digest.py --out DIR [--ticket OT-964] [--exclude SESSION_ID ...]

Writes one markdown digest per session plus INDEX.md. With --ticket, keeps only
sessions whose git branch, working directory or human prompts mention the key.
"""
import argparse
import collections
import glob
import json
import os
import re

PROMPT_MAX = 4000
PREV_MAX = 700


def text_of(content):
    if isinstance(content, str):
        return content
    return '\n'.join(c.get('text', '') for c in content if c.get('type') == 'text')


def is_tool_result(content):
    return isinstance(content, list) and any(c.get('type') == 'tool_result' for c in content)


def clip(s, n):
    s = s.strip()
    return s if len(s) <= n else s[:n] + f' …[+{len(s) - n} chars]'


def origin_kind(rec):
    origin = rec.get('origin')
    return origin.get('kind') if isinstance(origin, dict) else None


def human_prompt(rec):
    if rec.get('type') != 'user' or rec.get('isMeta') or rec.get('isSidechain'):
        return None
    if origin_kind(rec) not in (None, 'human'):
        return None
    content = rec.get('message', {}).get('content')
    if content is None or is_tool_result(content):
        return None
    t = text_of(content).strip()
    if not t or t.startswith(('<local-command-caveat>', '<local-command-stdout>', '<task-notification>', '<system-reminder>')):
        return None
    if t.startswith('<command-name>'):
        name = t.split('<command-name>')[1].split('</command-name>')[0]
        args = t.split('<command-args>')[1].split('</command-args>')[0] if '<command-args>' in t else ''
        return f'{name} {args}'.strip()
    return t


def mid_turn_prompt(rec):
    # Messages typed while the agent was working arrive as queued_command attachments.
    att = rec.get('attachment') or {}
    if rec.get('type') != 'attachment' or att.get('type') != 'queued_command':
        return None
    if (att.get('origin') or {}).get('kind') != 'human':
        return None
    return text_of(att.get('prompt') or '').strip() or None


def key_patterns(ticket):
    project, _, number = ticket.partition('-')
    text = re.compile(rf'\b{re.escape(project)}-{re.escape(number)}\b', re.IGNORECASE)
    # Worktree folders such as lyra-916 carry only the number.
    path = re.compile(rf'(?:\b{re.escape(ticket)}\b|-{re.escape(number)}(?:/|$))', re.IGNORECASE)
    return text, path


def digest(path, ticket_text, ticket_path):
    sid = os.path.basename(path)[:-6]
    proj = path.split('/')[-2]
    lines = []
    tools = collections.Counter()
    models = collections.Counter()
    branches, cwds = [], []
    first_ts = last_ts = None
    prev_assistant = ''
    pending_ask = set()
    seen_prompts = set()
    n_prompts = 0
    first_prompt = ''
    relevant = ticket_text is None

    def add_prompt(text, ts, tag):
        nonlocal prev_assistant, n_prompts, first_prompt, relevant
        norm = ' '.join(text.split())
        if norm in seen_prompts:
            return
        seen_prompts.add(norm)
        n_prompts += 1
        first_prompt = first_prompt or text
        if ticket_text is not None and ticket_text.search(text):
            relevant = True
        if prev_assistant:
            lines.append(f'  > [assistant before]: {clip(prev_assistant, PREV_MAX)}')
        lines.append(f'\n### USER {ts[:16] if ts else ""}{tag}\n{clip(text, PROMPT_MAX)}')
        prev_assistant = ''

    with open(path) as f:
        for raw in f:
            try:
                rec = json.loads(raw)
            except json.JSONDecodeError:
                continue
            ts = rec.get('timestamp')
            if ts:
                first_ts = first_ts or ts
                last_ts = ts
            branch, cwd = rec.get('gitBranch'), rec.get('cwd')
            if branch and branch not in branches:
                branches.append(branch)
                if ticket_text is not None and ticket_text.search(branch):
                    relevant = True
            if cwd and cwd not in cwds:
                cwds.append(cwd)
                if ticket_path is not None and ticket_path.search(cwd):
                    relevant = True

            p = human_prompt(rec)
            if p is not None:
                add_prompt(p, ts, '')
                continue
            p = mid_turn_prompt(rec)
            if p is not None:
                add_prompt(p, ts, ' (mid-turn)')
                continue

            if rec.get('type') == 'user' and is_tool_result(rec.get('message', {}).get('content')):
                for c in rec['message']['content']:
                    if c.get('type') == 'tool_result' and c.get('tool_use_id') in pending_ask:
                        res = c.get('content')
                        res = text_of(res) if isinstance(res, list) else str(res)
                        lines.append(f'  - [AskUserQuestion answer]: {clip(res, 1200)}')
                        pending_ask.discard(c['tool_use_id'])
                continue

            if rec.get('type') != 'assistant' or rec.get('isSidechain'):
                continue
            msg = rec.get('message', {})
            if msg.get('model'):
                models[f"{msg['model']}/{rec.get('effort') or '-'}"] += 1
            content = msg.get('content')
            if not isinstance(content, list):
                continue
            for c in content:
                if c.get('type') == 'text' and c.get('text', '').strip():
                    prev_assistant = c['text']
                if c.get('type') != 'tool_use':
                    continue
                name = c.get('name', '')
                inp = c.get('input', {}) or {}
                tools[name] += 1
                if name in ('Agent', 'Task'):
                    lines.append(
                        f"  - [Agent] type={inp.get('subagent_type')} model={inp.get('model')} "
                        f"desc={inp.get('description')!r}: {clip(inp.get('prompt', ''), 500)}")
                elif name == 'Skill':
                    lines.append(f"  - [Skill] {inp.get('skill')} {clip(str(inp.get('args', '') or ''), 200)}")
                elif name == 'AskUserQuestion':
                    qs = '; '.join(
                        f"Q: {q.get('question')} [{' | '.join(o.get('label', '') for o in q.get('options', []))}]"
                        for q in inp.get('questions', []))
                    lines.append(f'  - [AskUserQuestion] {clip(qs, 1500)}')
                    pending_ask.add(c.get('id'))
                elif name == 'Bash' and 'herdr' in (inp.get('command') or ''):
                    lines.append(f"  - [herdr] {clip(inp['command'], 300)}")
                elif name == 'Write':
                    lines.append(f"  - [Write] {inp.get('file_path')}")
                elif name.startswith('mcp__'):
                    lines.append(f"  - [MCP] {name.split('__', 2)[-1]} {clip(json.dumps(inp), 200)}")

    if prev_assistant:
        lines.append(f'  > [final assistant]: {clip(prev_assistant, 1500)}')
    header = [
        f'# Session {sid}',
        f'- project dir: {proj}',
        f"- cwd: {', '.join(cwds)}",
        f"- branches: {', '.join(branches)}",
        f'- time: {first_ts} -> {last_ts}',
        f'- human prompts: {n_prompts}',
        f'- models: {dict(models.most_common(4))}',
        f'- tools: {dict(tools.most_common(25))}',
    ]
    meta = {
        'sid': sid, 'proj': proj, 'start': first_ts or '', 'branches': branches,
        'prompts': n_prompts, 'first': clip(first_prompt.replace('\n', ' '), 160),
    }
    return '\n'.join(header + lines) + '\n', meta, relevant


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--out', required=True)
    parser.add_argument('--ticket')
    parser.add_argument('--exclude', action='append', default=[])
    parser.add_argument('--root', default=os.path.expanduser('~/.claude/projects'))
    args = parser.parse_args()

    ticket_text, ticket_path = key_patterns(args.ticket) if args.ticket else (None, None)
    os.makedirs(args.out, exist_ok=True)
    index = []
    for path in glob.glob(f'{args.root}/*/*.jsonl'):
        if os.path.basename(path)[:-6] in args.exclude:
            continue
        text, meta, relevant = digest(path, ticket_text, ticket_path)
        if meta['prompts'] == 0 or not relevant:
            continue
        meta['file'] = f"{meta['start'][:10] or 'undated'}_{meta['proj'].lstrip('-')}_{meta['sid'][:8]}.md"
        meta['bytes'] = len(text)
        with open(os.path.join(args.out, meta['file']), 'w') as f:
            f.write(text)
        index.append(meta)

    index.sort(key=lambda m: m['start'])
    total = sum(m['bytes'] for m in index)
    with open(os.path.join(args.out, 'INDEX.md'), 'w') as f:
        f.write(f'# Sessions{" for " + args.ticket if args.ticket else ""}: {len(index)}, {total // 1024} KB\n\n')
        for m in index:
            f.write(f"- {m['start'][:16]} {m['proj']} {m['sid'][:8]} prompts={m['prompts']} "
                    f"kb={m['bytes'] // 1024} branches={','.join(m['branches'])} file={m['file']}\n"
                    f"    first: {m['first']}\n")
    print(f'{len(index)} sessions, {total // 1024} KB -> {args.out}')


main()
