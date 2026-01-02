import json
import csv
import datetime
from datetime import timedelta, timezone

# Config
ID_ALUNO = 'b5a6a7f1-4eac-4dcf-9e93-186f91c60738'
ID_TURMA = '5fcb344f-b983-439f-a858-2b1289ef9638'
CSV_PATH = r'e:\Aplicativos\sped - Documentos\app_sped\db\ad-hoc\diario_agatha.csv'
JSON_PATH = r'e:\Aplicativos\sped - Documentos\app_sped\db\ad-hoc\migracao_agatha\json_agatha_banco.json'
OUTPUT_SQL = r'e:\Aplicativos\sped - Documentos\app_sped\db\ad-hoc\selects\insert_diario_agatha.sql'

# Mappings
STATUS_MAP = {
    'Presente': 'presente',
    'Falta': 'falta',
    'Abonada': 'abonada' # Verify this if possible
}

# TZ info: CSV is UTC-3. DB expects UTC.
BRT = timezone(timedelta(hours=-3))

def parse_csv_date(date_str):
    # Example: 30/07/2025 00:00
    try:
        dt = datetime.datetime.strptime(date_str, '%d/%m/%Y %H:%M')
        # Set as BRT then convert to UTC
        dt = dt.replace(tzinfo=BRT)
        dt_utc = dt.astimezone(timezone.utc)
        return dt_utc.strftime('%Y-%m-%d %H:%M:%S%z')
    except ValueError:
        return None

def main():
    # 1. Load existing items from JSON (key: id_item_sharepoint)
    existing_items = set()
    with open(JSON_PATH, 'r', encoding='utf-8') as f:
        data = json.load(f)
        for item in data:
            if item.get('id_item_sharepoint'):
                existing_items.add(str(item.get('id_item_sharepoint')))

    print(f"Loaded {len(existing_items)} existing items from JSON.")

    # 2. Read CSV and generate inserts
    inserts = []
    
    with open(CSV_PATH, 'r', encoding='utf-8-sig') as f: # utf-8-sig to handle BOM if present
        # Assuming semicolon delimiter based on 'head' output
        reader = csv.reader(f, delimiter=';')
        
        # We need to map columns by index based on the snippets:
        # RA...; Name; RA; Course; Mod; Mod2; Shift; Date; P1; P2; ...; ID (approx col 11 or 12?)
        # Let's inspect the header or first row in logic, but hardcoding based on snippet:
        # Line: RA-56515A30/07/2025;Agatha...;RA...;Tech...;25II...;RTD...;Tarde;30/07/2025 00:00;Falta;Falta;;6908;...
        # Indices (0-based):
        # 0: RA...
        # 1: Name
        # 2: RA
        # 3: Course
        # 4: Mod
        # 5: Mod2
        # 6: Shift
        # 7: Date (30/07/2025 00:00)
        # 8: P1 (Falta)
        # 9: P2 (Falta)
        # 10: ? (empty in snippet)
        # 11: ID (6908)
        
        # Verify this with user or inspection? I'll use logic to find the ID.
        # It looks like ID is the first numeric columns after P1/P2? 
        
        for row in reader:
            if not row: continue
            
            # Simple heuristic to find columns
            # Date is usually index 7
            date_str = row[7]
            p1_raw = row[8]
            p2_raw = row[9]
            # ID seems to be index 11
            id_sharepoint = row[11].strip()

            if not id_sharepoint:
                continue

            # Check if exists
            if id_sharepoint in existing_items:
                print(f"Skipping existing item {id_sharepoint}")
                continue

            # Process
            data_utc = parse_csv_date(date_str)
            if not data_utc:
                print(f"Invalid date: {date_str}")
                continue
                
            p1 = STATUS_MAP.get(p1_raw.strip(), 'presente') # Default fallback? or null?
            p2 = STATUS_MAP.get(p2_raw.strip(), 'presente')

            # Map specific keywords if they differ
            if 'presen' in p1_raw.lower(): p1 = 'presente'
            elif 'falta' in p1_raw.lower(): p1 = 'falta'
            elif 'abon' in p1_raw.lower(): p1 = 'abonada'
            
            if 'presen' in p2_raw.lower(): p2 = 'presente'
            elif 'falta' in p2_raw.lower(): p2 = 'falta'
            elif 'abon' in p2_raw.lower(): p2 = 'abonada'

            # Construct SQL
            # Column list: id, id_aluno, id_turma, id_item_sharepoint, data, p1, p2, p3, p4
            # We need to gen a uuid for id? Postgres DEFAULT gen_random_uuid() handles it if we omit ID.
            sql = f"""
INSERT INTO public.diario (id_aluno, id_turma, id_item_sharepoint, data, p1, p2, p3, p4, sync_sharepoint, atualizado)
VALUES ('{ID_ALUNO}', '{ID_TURMA}', '{id_sharepoint}', '{data_utc}', '{p1}', '{p2}', NULL, NULL, true, true);"""
            inserts.append(sql)

    # 3. Write SQL file
    with open(OUTPUT_SQL, 'w', encoding='utf-8') as f:
        f.write("-- Script gerado automaticamente para importar dados da Agatha via CSV\n")
        f.write("BEGIN;\n")
        for sql in inserts:
            f.write(sql.strip() + "\n")
        f.write("COMMIT;\n")
    
    print(f"Generated {len(inserts)} inserts.")

if __name__ == '__main__':
    main()
