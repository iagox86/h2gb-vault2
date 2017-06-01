import Ember from 'ember';

export default Ember.Route.extend({
  dataStore: Ember.inject.service('data-store'),
  model(params) {
    return this.get('dataStore').findBlock(params.workspace_id, params.memory_block_name);
  },
});
