import Ember from 'ember';

export default Ember.Component.extend({
  data_xrefs: Ember.computed('entry.xrefs', function() {
    return this.get('entry')['xrefs']['data'];
  }),
  code_xrefs: Ember.computed('entry.xrefs', function() {
    return this.get('entry')['xrefs']['code'];
  }),
});
