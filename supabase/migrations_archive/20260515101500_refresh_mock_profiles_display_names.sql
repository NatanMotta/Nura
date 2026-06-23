-- Refresh mock profiles with more realistic identities for testing UI flows.

update public.profiles p
set
  display_name = v.display_name,
  bio = v.bio
from (
  values
    ('giannigiove02@gmail.com', 'Gianni Giove', 'Singer-songwriter pop/elettronico, demo lab Milano.'),
    ('fraanzescoo@icloud.com', 'Francesco Lillo', 'Producer indie-pop, focus su topline e arrangiamento.'),
    ('magaldifilippo@gmail.com', 'Filippo Magaldi', 'Beatmaker alt-pop con setup live ibrido.'),
    ('natamottadelli@gmail.com', 'Natan Mottadelli', 'Founder Nura, scouting artisti e sviluppo prodotto.'),
    ('sala88sala@icloud.com', 'Stefano Sala', 'A&R freelance orientato a progetti crossover.'),
    ('asd@gmail.com', 'Natan Test', 'Profilo test artista per QA flussi social e audio.')
) as v(email, display_name, bio)
join auth.users u on u.email = v.email
where p.id = u.id;
