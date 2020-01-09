# -*- coding:utf-8 -*-

import sys

def parse(kvs_str):
    kvs_str = kvs_str.strip()
    kvs = {}
    if len(kvs_str) == 0:
        return kvs
    for it in kvs_str.split('#'):
        kv = it.split('=')
        assert len(kv) == 2, it
        kvs['{' + kv[0] + '}'] = kv[1]
    return kvs

def render(kvs):
    while True:
        line = sys.stdin.readline()
        if not line:
            break
        if len(line) == 0:
            continue

        line = line[:-1]

        for k, v in kvs.items():
            line = line.replace(k, v)
        print line

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print '[render_templ.py] usage: <bin> render_str(k=v#k=v:..) < input'
        sys.exit(1)
    render(parse(sys.argv[1]))
