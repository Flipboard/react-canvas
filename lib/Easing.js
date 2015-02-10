// Penner easing equations
// https://gist.github.com/gre/1650294

var Easing = {

  linear: function (t) {
    return t;
  },

  easeInQuad: function (t) {
    return Math.pow(t, 2);
  },

  easeOutQuad: function (t) {
    return t * (2-t);
  },

  easeInOutQuad: function (t) {
    return t < .5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  },

  easeInCubic: function (t) {
    return t * t * t;
  },

  easeOutCubic: function (t) {
    return (--t) * t * t + 1;
  },

  easeInOutCubic: function (t) {
    return t < .5 ? 4 * t * t * t : (t-1) * (2*t - 2) * (2*t - 2) + 1;
  }

};

module.exports = Easing;
