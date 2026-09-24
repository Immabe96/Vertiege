import { queryClient } from '@/lib/query';

describe('queryClient', () => {
  afterAll(() => queryClient.clear());

  it('applies the F0 defaults', () => {
    const queries = queryClient.getDefaultOptions().queries;
    expect(queries?.staleTime).toBe(30_000);
    expect(queries?.gcTime).toBe(5 * 60_000);
    expect(queries?.retry).toBe(1);
    expect(queries?.refetchOnWindowFocus).toBe(false);
    expect(queryClient.getDefaultOptions().mutations?.retry).toBe(0);
  });

  it('dedupes concurrent fetches for the same key', async () => {
    const queryFn = jest.fn().mockResolvedValue('payload');
    const query = { queryKey: ['probe', 1], queryFn } as const;

    const [first, second] = await Promise.all([
      queryClient.fetchQuery(query),
      queryClient.fetchQuery(query),
    ]);

    expect(first).toBe('payload');
    expect(second).toBe('payload');
    expect(queryFn).toHaveBeenCalledTimes(1);
  });

  it('serves a cached value without refetching while fresh', async () => {
    const queryFn = jest.fn().mockResolvedValue('payload');
    const query = { queryKey: ['probe', 2], queryFn } as const;

    await queryClient.fetchQuery(query);
    await queryClient.fetchQuery(query);

    expect(queryFn).toHaveBeenCalledTimes(1);
  });
});
