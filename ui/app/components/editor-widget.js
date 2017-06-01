import Ember from 'ember';

export default Ember.Component.extend({
  actions: {
    updateBasicType() {
      let address = this.get('address');
      let type = this.get('type');
      let request = {
        updates: [
          {
            action: 'define_basic_type',
            block_name: this.get('block_name'),
            address: parseInt(address),
            type: type,
          }
        ]
      };

      Ember.$.ajax('http://localhost:4567/api/workspaces/' + this.get('workspace_id') + '/update', {
        data: JSON.stringify(request),
        contentType: 'application/json',
        type: 'POST',
      }).then(() => {
        window.location.reload();
      });
    },
  }
});
