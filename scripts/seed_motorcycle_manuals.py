#!/usr/bin/env python3
"""
Seed Motorcycle Manuals into Supabase.
Lee assets/data/motorcycle_manuals.json e inserta las fichas técnicas en Supabase.
Deduplica claves en memoria para evitar errores ON CONFLICT en lotes de PostgreSQL.
"""

import json
import os
import sys
import urllib.request
import urllib.error

if sys.platform == 'win32':
    sys.stdout.reconfigure(encoding='utf-8')

def load_env():
    env_vars = {}
    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, val = line.split('=', 1)
                    env_vars[key.strip()] = val.strip().strip('"').strip("'")
    return env_vars

def main():
    env = load_env()
    supabase_url = os.environ.get('SUPABASE_URL') or env.get('SUPABASE_URL')
    supabase_key = os.environ.get('SUPABASE_SERVICE_KEY') or os.environ.get('SUPABASE_ANON_KEY') or env.get('SUPABASE_ANON_KEY')

    if not supabase_url or not supabase_key:
        print("[!] ERROR: Configura SUPABASE_URL y SUPABASE_ANON_KEY en tu archivo .env")
        sys.exit(1)

    json_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'assets', 'data', 'motorcycle_manuals.json')
    if not os.path.exists(json_path):
        print(f"[!] No se encontró el archivo: {json_path}")
        sys.exit(1)

    with open(json_path, 'r', encoding='utf-8') as f:
        raw_manuals = json.load(f)

    # Deduplicar en memoria por (make, model, year)
    seen = set()
    manuals = []
    for m in raw_manuals:
        m.pop('id', None)
        k = (str(m.get('make','')).strip().lower(), str(m.get('model','')).strip().lower(), str(m.get('year','')).strip().lower())
        if k not in seen and k[0] and k[1]:
            seen.add(k)
            manuals.append(m)

    total = len(manuals)
    print(f"[*] Registros únicos a insertar: {total}")

    batch_size = 150
    endpoint = f"{supabase_url.rstrip('/')}/rest/v1/motorcycle_manuals?on_conflict=make,model,year"
    headers = {
        "apikey": supabase_key,
        "Authorization": f"Bearer {supabase_key}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }

    inserted = 0
    for i in range(0, total, batch_size):
        batch = manuals[i:i + batch_size]
        payload = json.dumps(batch).encode('utf-8')

        req = urllib.request.Request(endpoint, data=payload, headers=headers, method='POST')
        try:
            with urllib.request.urlopen(req) as resp:
                if resp.status in (200, 201):
                    inserted += len(batch)
                    pct = (inserted * 100) // total
                    print(f"  -> Sincronizados: {inserted}/{total} ({pct}%)")
        except urllib.error.HTTPError as e:
            err_body = e.read().decode('utf-8', errors='ignore')
            print(f"[!] Error en lote {i//batch_size + 1}: HTTP {e.code} - {err_body[:200]}")
        except Exception as e:
            print(f"[!] Error en lote {i//batch_size + 1}: {e}")

    print(f"[OK] Sincronización exitosa completada: {inserted}/{total}")

if __name__ == '__main__':
    main()
