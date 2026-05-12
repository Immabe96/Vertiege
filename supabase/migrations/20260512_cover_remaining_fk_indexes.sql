-- Add leftmost covering indexes for composite-primary-key tables whose foreign
-- key columns were only indexed as a trailing key.

create index if not exists idx_channel_reads_channel_id
  on public.channel_reads(channel_id);

create index if not exists idx_resident_ranks_rank_id
  on public.resident_ranks(rank_id);
