import os
import urllib.request

headers = {'User-Agent': 'MyAutoGuide-SkillInstaller/1.0'}

skills_to_install = [
    # 1. Andrej Karpathy Skill
    {
        'url': 'https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/skills/karpathy-guidelines/SKILL.md',
        'dest': '.agents/skills/andrej-karpathy-skills/SKILL.md'
    },
    {
        'url': 'https://raw.githubusercontent.com/multica-ai/andrej-karpathy-skills/main/skills/karpathy-guidelines/SKILL.md',
        'dest': '.agents/skills/karpathy-guidelines/SKILL.md'
    },
    # 2. Ponytail
    {
        'url': 'https://raw.githubusercontent.com/DietrichGebert/ponytail/main/skills/ponytail/SKILL.md',
        'dest': '.agents/skills/ponytail/SKILL.md'
    },
    {
        'url': 'https://raw.githubusercontent.com/DietrichGebert/ponytail/main/skills/ponytail-audit/SKILL.md',
        'dest': '.agents/skills/ponytail-audit/SKILL.md'
    },
    {
        'url': 'https://raw.githubusercontent.com/DietrichGebert/ponytail/main/skills/ponytail-review/SKILL.md',
        'dest': '.agents/skills/ponytail-review/SKILL.md'
    },
    # 3. Agentring
    {
        'url': 'https://raw.githubusercontent.com/mutonby/agentring/main/skills/agentring/SKILL.md',
        'dest': '.agents/skills/agentring/SKILL.md'
    },
    {
        'url': 'https://raw.githubusercontent.com/mutonby/agentring/main/skills/agentring/references/setup.md',
        'dest': '.agents/skills/agentring/references/setup.md'
    }
]

print("Iniciando instalación de skills personalizadas...")

for item in skills_to_install:
    url = item['url']
    dest = item['dest']
    dest_dir = os.path.dirname(dest)
    os.makedirs(dest_dir, exist_ok=True)
    
    try:
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=15) as res:
            content = res.read().decode('utf-8')
        with open(dest, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"✔ Instalado exitosamente: {dest} ({len(content)} caracteres)")
    except Exception as e:
        print(f"❌ Error descargando {url} -> {dest}: {e}")

print("\nInstalación finalizada.")
