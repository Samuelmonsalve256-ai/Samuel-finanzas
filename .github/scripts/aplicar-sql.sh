#!/usr/bin/env bash
# Aplica en Supabase los archivos nuevos de supabase/migraciones (los ya aplicados se saltan).
source "$(dirname "$0")/supabase.sh"
aplicar_migraciones
