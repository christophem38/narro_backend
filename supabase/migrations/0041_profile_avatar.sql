-- Avatar « personnage » du profil : id d'un dessin bi-ton Élocia (ex. "e07"),
-- servi en statique depuis /public/avatars/elocia/<id>.svg côté front.
-- null = pas de choix → le front retombe sur les initiales. Aucune donnée
-- personnelle : juste un identifiant de dessin.
alter table public.elocia_profiles
  add column if not exists avatar text;
