-- Íconos de categoría: se pasa de emojis a íconos de línea (un solo estilo en toda la app).
-- Cada emoji guardado se cambia por su ícono equivalente; los que no tienen equivalente
-- quedan vacíos y la app elige el ícono por el nombre de la categoría. No toca movimientos.

update public.categorias c
set icono = m.icono
from (values
  ('🏠','ti-home'),('🍔','ti-tools-kitchen-2'),('🛒','ti-shopping-cart'),('☕','ti-coffee'),('🍺','ti-beer'),
  ('🚗','ti-car'),('🏍','ti-motorbike'),('⛽','ti-gas-station'),('🔧','ti-tool'),('🛠','ti-tools'),
  ('🚌','ti-bus'),('🅿','ti-parking'),('💡','ti-bulb'),('💧','ti-droplet'),('📱','ti-device-mobile'),
  ('🌐','ti-wifi'),('📺','ti-device-tv'),('💊','ti-pill'),('🏥','ti-stethoscope'),('💇','ti-scissors'),
  ('🏋','ti-barbell'),('🎓','ti-school'),('📚','ti-book'),('👕','ti-shirt'),('🧒','ti-baby-carriage'),
  ('🐶','ti-paw'),('🎉','ti-confetti'),('🎬','ti-movie'),('✈','ti-plane'),('🎁','ti-gift'),
  ('💼','ti-briefcase'),('👷','ti-users'),('💰','ti-coins'),('💵','ti-cash'),('💳','ti-credit-card'),
  ('🏦','ti-building-bank'),('📈','ti-chart-line'),('🧾','ti-receipt'),('📦','ti-package'),('🔒','ti-lock')
) as m(emoji, icono)
where replace(c.icono, chr(65039), '') = m.emoji;

update public.categorias set icono = null
where icono is not null and icono !~ '^ti-[a-z0-9-]+$';
