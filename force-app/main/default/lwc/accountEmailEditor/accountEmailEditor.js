import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { LightningElement, api } from 'lwc';

export default class AccountEmailEditor extends LightningElement {

  @api recordId;

    handleSuccess(event) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Success',
            message: 'E-mail has been updated!',
            variant: 'success'
        }));
    }
}