-- Série (« streak ») de complétion des missions hebdomadaires.
-- mission_streak       : nombre de semaines consécutives bouclées (3/3).
-- mission_streak_week  : index de semaine (lundi UTC) de la dernière semaine comptée,
--                        stocké en texte (ex. "2953"). Sert à savoir si la série
--                        continue (semaine précédente) ou repart de zéro (semaine sautée).
alter table public.elocia_profiles
  add column if not exists mission_streak integer not null default 0,
  add column if not exists mission_streak_week text;
