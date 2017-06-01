import Ember from 'ember';

export default Ember.Component.extend({
  dataStore: Ember.inject.service('data-store'),
  init() {
    this._super(...arguments);
    this.type = 'uint8_t';
  },

  hasNoType: Ember.computed('type', function() {
    return Ember.isBlank(this.get('type'));
  }).readOnly(),

  actions: {
    updateBasicType() {
      let address = this.get('address');
      let type = this.get('type');
      let workspace_id = this.get('workspace_id');
      let block_name = this.get('block_name');

      let request = {
        updates: [
          {
            action: 'define_basic_type',
            address: parseInt(address),
            block_name,
            type,
          }
        ]
      };

      Ember.$.ajax('http://localhost:4567/api/workspaces/' + workspace_id + '/update', {
        data: JSON.stringify(request),
        contentType: 'application/json',
        type: 'POST',
      }).then(data => {
        return this.get('dataStore').findBlock(workspace_id, block_name);
      });
    },
  }
});
