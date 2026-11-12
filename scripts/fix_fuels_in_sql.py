import json
import re

with open('supabase/migrations/20261112_add_autonal_and_autoland_catalog.sql', 'r', encoding='utf-8') as f:
    sql = f.read()

# Allowed values: 'Gasolina', 'Diésel', 'Híbrido', 'Eléctrico', 'Gas/Gasolina'
# Let's replace 'Hibrido' with 'Híbrido'
# 'Diesel' with 'Diésel'
# 'Electrico' with 'Eléctrico'

fixed_sql = sql.replace("'Hibrido'", "'Híbrido'")
fixed_sql = fixed_sql.replace("'Diesel'", "'Diésel'")
fixed_sql = fixed_sql.replace("'Electrico'", "'Eléctrico'")

with open('supabase/migrations/20261112_add_autonal_and_autoland_catalog.sql', 'w', encoding='utf-8') as f:
    f.write(fixed_sql)

print("Reemplazos realizados. Verificando valores...")

allowed = {'Gasolina', 'Diésel', 'Híbrido', 'Eléctrico', 'Gas/Gasolina'}
found_fuels = set(re.findall(r",\s*'([^']+)',\s*14\.5", fixed_sql))
print("Combustibles encontrados en el SQL:", found_fuels)
invalid = found_fuels - allowed
if invalid:
    print("ALERTA - Valores no permitidos:", invalid)
else:
    print("TODOS los valores cumplen con el check constraint catalogo_modelos_tipo_combustible_check!")
