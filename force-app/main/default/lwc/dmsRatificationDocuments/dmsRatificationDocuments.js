import { NavigationMixin } from 'lightning/navigation';
import { LightningElement, wire, track, api } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAllRatificationDocuments from '@salesforce/apex/DmsRatificationDocumentsController.getAllRatificationDocuments';
import createFinalRatificationDocument from '@salesforce/apex/DmsRatificationDocumentsController.createFinalRatificationDocument';
import getFinalUrlForDownload from '@salesforce/apex/DmsRatificationDocumentsController.getFinalUrlForDownload';


const ACTIONS = [
    { label: 'Preview', name: 'show_details' },
];

const COLS = [

    { label: 'Document Name', fieldName: 'documentName'},
    { label: 'File Type', fieldName: 'fileType', initialWidth: 110},
    { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
    { label: 'Last Modified By', fieldName: 'lastModifiedBy', type: 'text'},
    { type: 'action',
        typeAttributes: { rowActions: ACTIONS },
    },

];

export default class DmsRatificationDocuments extends NavigationMixin(LightningElement){

    @track initialToDate = '';
    @track initialFromDate = '';
    @track modalShow = false;
    @track attachments = [];
    @track columns = COLS;
    @track thereAreRecords = false;
    @track displaySpinner = false;

    connectedCallback() {
        this.initialToDate = this.getInitialToDate();
        this.initialFromDate = this.getInitialFromDate();
    }

    listRatificationDocuments(event){
        
        console.log('>>> Regards from method findRatificationDocuments()');

        this.displaySpinner = true;

        let dateFrom = this.template.querySelector(".cmp-in-fromDate").value;
        let dateTo = this.template.querySelector(".cmp-in-toDate").value;

        getAllRatificationDocuments({fromDate : dateFrom, toDate : dateTo})
            .then((data) => {

                console.log('>>> entered into then. The obtained data is');
                console.log (JSON.parse(JSON.stringify(data)));

                if (data.length > 0) {
                    this.thereAreRecords = true;
                    this.attachments = this.normalizeFieldsOnData(data);
                    this.displaySpinner = false;
                    
                } else {
                    this.thereAreRecords = false;
                    this.displaySpinner = false;
                    this.showToastMessage('No documents found, try using a different date range', 'info');
                }

            })
            .catch(error => {
                console.log('>>> Error in listRatificationDocuments()');
                console.log(JSON.parse(JSON.stringify(error)));

                this.displaySpinner = false;
                this.showToastMessage('There was an error. Please reload the page and try again', 'error');
            })

    }

    constructFinalDocument(event){

        this.displaySpinner = true;
        this.showToastMessage('Working, please wait', 'info');

        console.log('>>> Regards from method constructFinalDocument()... be patient!');

        let dateFrom = this.template.querySelector(".cmp-in-fromDate").value;
        let dateTo = this.template.querySelector(".cmp-in-toDate").value;

        createFinalRatificationDocument({fromDate : dateFrom, toDate : dateTo})
            .then((data) => {

                console.log('>>> entered into then of constructFinalDocument() The obtained data is');
                console.log (JSON.parse(JSON.stringify(data)));

                let linksArray = [];
                for (let index = 0; index < data.length; index++) {
                    linksArray[index] = data[index];
                }

                this.getFinalDownloadLink(linksArray);

            })
            .catch(error => {
                console.log('>>> Error in listRatificationDocuments()');
                console.log(JSON.parse(JSON.stringify(error)));

                this.displaySpinner = false;
                this.showToastMessage('There was an error. Please reload the page and try again', 'error');
            })
        


    }

    getFinalDownloadLink(downloadLinks){

        getFinalUrlForDownload({documentPublicUrls : downloadLinks})
            .then((data) => {

                console.log('>>> Success in getFinalDownloadLink(). Heres the final link');
                console.log(JSON.parse(JSON.stringify(data)));

                console.log(data[0]);
                console.log(data[1]);

                let a = document.createElement('a');
                a.style.display = 'none';
                document.body.appendChild(a);

                a.setAttribute('href', JSON.parse(JSON.stringify(data)));
                //a.setAttribute('target', '_blank');
                //a.setAttribute('download', 'Documents For Ratification ' + this.getInitialToDate);
                a.setAttribute('download', 'true')
                a.click();
                
                this.displaySpinner = false;
                this.showToastMessage('Document succesfully created', 'success');

            })
            .catch(error => {
                console.log('>>> Error in getFinalDownloadLink()');
                console.log(JSON.parse(JSON.stringify(error)));

                this.displaySpinner = false;
                this.showToastMessage('There was an error. Please reload the page and try again', 'error');
            })
    }
    

    normalizeFieldsOnData(data){

        let currentData = [];

            data.forEach((row) => {

                let rowData = {};

                rowData.Id = row.Id;
                rowData.documentName = row.ContentDocument.Title;
                rowData.fileType = row.ContentDocument.FileType;
                rowData.createdDate = row.ContentDocument.CreatedDate;
                rowData.lastModifiedBy = row.ContentDocument.LastModifiedBy.Name;
                rowData.contentDocumentId = row.ContentDocumentId;
                
                currentData.push(rowData);
            });

        return currentData;

    }

    getInitialToDate(event){
        var today = new Date();
        var dd = String(today.getDate()).padStart(2, '0');
        var mm = String(today.getMonth() + 1).padStart(2, '0');
        var yyyy = today.getFullYear();
        today = yyyy + '-' + mm + '-' + dd;

        return today;
    }

    getInitialFromDate(event){
        let dateTwoWeeksAgo = new Date();
        dateTwoWeeksAgo.setDate(dateTwoWeeksAgo.getDate() - 14);

        let twoWeeksAgoStr = dateTwoWeeksAgo.toLocaleString();
        let onlyTheDatePart = twoWeeksAgoStr.substr(0, twoWeeksAgoStr.indexOf(',')); 

        let stringIntoArray = onlyTheDatePart.split('/'); 
        let finalDate = stringIntoArray[2] + '-' +  stringIntoArray[0] + '-' + stringIntoArray[1];

        return finalDate;
    }

    handleRowAction(event) {

        const actionName = event.detail.action.name;
        const defaultRow = event.detail.row;
        const row = JSON.parse(JSON.stringify(defaultRow));
        
        let id;
        let property;
        for (property in row) {
            if (property === 'Id'){
                id = row[property];
            }
        }

        let parsedAttachments = JSON.parse(JSON.stringify(this.attachments));

        let contentDocumentId;
        switch (actionName) {
            case 'show_details':

                for (let index = 0; index < parsedAttachments.length; index++) {

                    if(String(parsedAttachments[index].Id) === String(id)){
                        contentDocumentId = parsedAttachments[index].contentDocumentId;
                    }
                }

                this.showPreview(contentDocumentId);

                break;
            default:
                break;
        }
    }


    showPreview(contentDocumentId) {
        
        console.log('>>> Regards from method showPreview(). Showing preview for Id ' + contentDocumentId);
        
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state : {
                recordIds: contentDocumentId,
                selectedRecordId: contentDocumentId
            }
        })
    }

    openDocumentsModal(event){
        this.modalShow = true;
    }

    closeDocumentsModal(event){
        this.modalShow = false;
    }

    showToastMessage(paramMessage, paramVariant){
        
        //Variant could be: success, warning, error
        this.dispatchEvent(
            new ShowToastEvent({
                title: paramVariant,
                message: paramMessage,
                variant: paramVariant
            })
        );
    }


}