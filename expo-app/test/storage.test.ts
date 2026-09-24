import { storage } from '@/lib/storage';

describe('storage', () => {
  beforeEach(() => storage.clear());

  it('round-trips strings', () => {
    storage.setString('k', 'v');
    expect(storage.getString('k')).toBe('v');
    expect(storage.keys()).toContain('k');
  });

  it('round-trips numbers and booleans', () => {
    storage.setNumber('n', 42);
    storage.setBoolean('b', true);
    expect(storage.getNumber('n')).toBe(42);
    expect(storage.getBoolean('b')).toBe(true);
  });

  it('round-trips JSON', () => {
    storage.setJSON('obj', { a: 1, nested: ['x'] });
    expect(storage.getJSON('obj')).toEqual({ a: 1, nested: ['x'] });
  });

  it('returns undefined for missing keys', () => {
    expect(storage.getString('nope')).toBeUndefined();
    expect(storage.getJSON('nope')).toBeUndefined();
  });

  it('drops corrupt JSON instead of throwing', () => {
    storage.setString('bad', '{not json');
    expect(storage.getJSON('bad')).toBeUndefined();
    expect(storage.getString('bad')).toBeUndefined();
  });

  it('clear() removes everything', () => {
    storage.setString('a', '1');
    storage.setString('b', '2');
    storage.clear();
    expect(storage.keys()).toEqual([]);
  });
});
