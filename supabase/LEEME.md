# Mis Finanzas: proteger tus datos con inicio de sesión

Desde esta versión, Mis Finanzas pide **correo y contraseña**. Sigue estos pasos **en orden**.
Tu proyecto de Supabase es **"Finanzas de RICH"** (`https://hcwgtyjgscgdnxkrcjqf.supabase.co`).

> Los nombres de los menús de Supabase cambian a veces. Si un botón no aparece con el nombre
> exacto, busca el más parecido en la misma sección.

---

## Paso 1: Crear tu usuario

1. Entra a <https://supabase.com/dashboard> y abre **Finanzas de RICH**.
2. En el menú izquierdo abre **Authentication → Users**.
3. Pulsa **Add user → Create new user**.
4. Escribe tu **correo** y una **contraseña segura** (guárdala bien).
5. Marca **Auto Confirm User** y pulsa **Create user**.

## Paso 2: Que nadie más pueda crear cuentas

1. En **Authentication**, abre **Sign In / Providers** (en versiones anteriores: **Providers** o **Settings**).
2. Comprueba que **Email** esté activado.
3. **Desactiva** **Allow new users to sign up** y guarda.

## Paso 3: Entrar a la app

1. Abre Mis Finanzas (en el iPhone o en el Mac) y entra con el correo y la contraseña del paso 1.
2. Deben aparecer todos tus datos como siempre.

> En este punto la app ya pide contraseña, pero la base de datos todavía está abierta.
> El paso 4 es el que la cierra.

## Paso 4: Cerrar la base de datos

1. En Supabase abre **SQL Editor → New query**.
2. Copia todo el contenido de `supabase/seguridad.sql` y pégalo.
3. **Cambia** `TU_CORREO@ejemplo.com` por tu correo (el del paso 1), entre las comillas.
4. Pulsa **Run**.
5. Abajo debe aparecer una tabla con 5 filas (`ajustes`, `capital`, `categorias`, `compromisos`,
   `registros`), todas con `rls_activo = true` y `reglas = 1`.
   - Si sale *"No existe un usuario con el correo…"*, revisa que el correo esté bien escrito.

## Paso 5: Comprobar

1. Recarga Mis Finanzas: tus datos deben seguir apareciendo y el punto junto al nombre debe estar verde.
2. Abre **Ajustes** (⚙️): verás *"Conectado como tu correo"* y el botón **Cerrar sesión**.

---

## La tarea que evita que Supabase se pause

El archivo `.github/workflows/mantener-activo.yml` visita la base de datos cada 3 días.
Para comprobar que funciona: en GitHub abre el repositorio → pestaña **Actions** →
**Mantener Supabase activo** → **Run workflow**. Debe terminar con un ✓ verde.

- Si sale ❌, abre la ejecución: casi siempre es porque el proyecto ya estaba pausado. Reactívalo
  en Supabase con **Resume project**.
- GitHub apaga las tareas automáticas de un repositorio que pasa **60 días sin cambios** y te avisa
  por correo. Si te llega ese correo, entra a **Actions** y pulsa **Enable workflow**.

## Si olvidas la contraseña

En Supabase: **Authentication → Users**, borra tu usuario y créalo de nuevo con el mismo correo
y una contraseña nueva (paso 1). Tus datos no se pierden. Después vuelve a ejecutar
`seguridad.sql` (paso 4), porque el usuario nuevo tiene otro identificador.
