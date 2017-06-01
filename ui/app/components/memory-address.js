import Ember from 'ember';

export default Ember.Component.extend({
  // Get rid of the <div> around it
  tagName: '',

  actions: {
    addressclick(address) {
      Ember.$('html, body').animate({scrollTop: Ember.$('#address-' + address).offset().top + 'px'}, 'fast');
    }
  },
});
