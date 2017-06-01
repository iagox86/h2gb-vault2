import Ember from 'ember';

const { $ } = Ember;

export default Ember.Component.extend({
  init() {
    this._super(...arguments);
    this.onBodyClick = event => {
      let target = $(event.target);
      if (target.is('.operations') || target.is('.operations >')) {
        return;
      }
      $('body').off('click', this.onBodyClick);
      this.set('open', false);
    };
  },

  actions: {
    toggle() {
      let isOpen = this.get('open');

      if (isOpen) {
        this.set('open', false)
        $('body').off('click', this.onBodyClick);
      } else {
        this.set('open', true)

        setTimeout(() => {
          $('body').on('click', this.onBodyClick);
        });
      }
    }
  }
});
