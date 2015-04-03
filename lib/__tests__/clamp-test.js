jest.dontMock('../clamp.js');

var clamp = require('../clamp');

describe('clamp', function() {
  it('returns the min if n is less than min', function() {
    expect(clamp(-1, 0, 1)).toBe(0);
  });

  it('returns the max if n is greater than max', function() {
    expect(clamp(2, 0, 1)).toBe(1);
  });

  it('returns n if n is between min and max', function() {
    expect(clamp(0.5, 0, 1)).toBe(0.5);
  });
});
