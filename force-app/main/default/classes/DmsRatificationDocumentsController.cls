/**
 * @File Name          : DmsRatificationDocumentsController.cls
 * @Description        : 
 * @Author             : emmanuel.martinez@tengo.co
 * @Group              : 
 * @Last Modified By   : emmanuel.martinez@tengo.co
 * @Last Modified On   : 05/03/2020, 11:34:20
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    13/02/2020   emmanuel.martinez@tengo.co     Initial Version
**/
public with sharing class DmsRatificationDocumentsController {
    
    @AuraEnabled
    public static List<ContentDocumentLink> getAllRatificationDocuments(String fromDate, String toDate) {
        
        Date paramFromDate = Date.valueOf(fromDate + 'T00:00:00Z');
        Date paramToDate = Date.valueOf(toDate + 'T00:00:00Z');
        
        
        List<DocumentExecution__c> docsPendingRatification = [SELECT    Id 
        
                                                              FROM      DocumentExecution__c 
                                                              
                                                              WHERE     Ratification__c = true 
                                                                        AND Ratification_Date__c >= :paramFromDate
                                                                        AND Ratification_Date__c <= :paramToDate];

        List<ContentDocumentLink> listOfAttachments = new List<ContentDocumentLink>();
        
        if( ! docsPendingRatification.isEmpty() ) {
            
            List<Id> documentExecutionIds = new List<Id>();                                                                 
            for(DocumentExecution__c element : docsPendingRatification){
                documentExecutionIds.add(element.id);
            }
            
            listOfAttachments = [SELECT Id, 
                                        ContentDocumentId,
                                        ContentDocument.Title, 
                                        ContentDocument.FileType, 
                                        ContentDocument.FileExtension, 
                                        ContentDocument.LastModifiedBy.Name, 
                                        ContentDocument.CreatedDate
                                                                    
                                FROM    ContentDocumentLink 
                                                            
                                WHERE   LinkedEntityId IN :documentExecutionIds];
            
        }
                                              
        return listOfAttachments;

    }
    
    
    @AuraEnabled
    public static List<String> createFinalRatificationDocument(String fromDate, String toDate){
        
        //Get the initial list of all the Document Executions that are marked as pending for ratification
        Date paramFromDate = Date.valueOf(fromDate + 'T00:00:00Z');
        Date paramToDate = Date.valueOf(toDate + 'T00:00:00Z');
        String today = Datetime.now().format('yyyy-MM-dd');
        
        List<DocumentExecution__c> docsPendingRatification = [SELECT    Id 
        
                                                              FROM      DocumentExecution__c 
                                                              
                                                              WHERE     Ratification__c = true 
                                                                        AND Ratification_Date__c >= :paramFromDate
                                                                        AND Ratification_Date__c <= :paramToDate];

        //Extract only the ids of the Document Executions found                                                                
        List<Id> documentExecutionIds = new List<Id>();                                                                 
        for(DocumentExecution__c element : docsPendingRatification){
            documentExecutionIds.add(element.id);
        }
                                                                        
        //If there are Document Executions found, select all the pdfs attached to that Document Execution    
        List<ContentDocumentLink> listOfAttachments = new List<ContentDocumentLink>();
        listOfAttachments = [SELECT Id, 
                                    ContentDocument.Title, 
                                    ContentDocument.FileType, 
                                    ContentDocument.FileExtension, 
                                    ContentDocument.LastModifiedBy.Name, 
                                    ContentDocument.LastModifiedDate, 
                                    ContentDocument.CreatedDate,
                                    ContentDocument.LatestPublishedVersionId
                                                                
                            FROM    ContentDocumentLink 
                                                
                            WHERE   LinkedEntityId IN :documentExecutionIds];
        

        
        //For every attachment found
        String recordsToShowInHTML = '';
        for(ContentDocumentLink attachment : listOfAttachments){
            
            //Create the HTML code for this attachment to be later printed in the Summary pdf
            recordsToShowInHTML += '<tr><td style="border: 0.5px solid black;"><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">&nbsp;' + attachment.ContentDocument.Title + '</span></td><td style="border: 0.5px solid black; font-family: &quot;Lucida Sans Unicode&quot;"><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">&nbsp;' + attachment.ContentDocument.CreatedDate + '</span></td><td style="border: 0.5px solid black; font-family: &quot;Lucida Sans Unicode&quot;"><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">&nbsp;' + attachment.ContentDocument.LastModifiedDate + '</span></td><td style="border: 0.5px solid black; font-family: &quot;Lucida Sans Unicode&quot;"><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">&nbsp;' + attachment.ContentDocument.LastModifiedBy.Name + '</span></td></tr>';
            
        }
        
        //Initialice API client
        Api2PdfClient a2pClient = new Api2PdfClient('5f027945-b58f-45c8-88dc-27f9e9fb9ecc');
        
        //Create the first  page of the document, a summary of all attachments found in System sent as an HTML table 
        String htmlFullContent = '<p style="text-align: right;"><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">Date: ' + today + ' (y/m/d)</span></p><p style="text-align: center;">  <br></p><p style="text-align: center;"><strong><span style="font-size: 14px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;"><u>Documents Pending for Ratification</u></span></strong></p><p style="text-align: center;"><span style="font-size: 14px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">From: ' + fromDate + ' To: ' + toDate + ' </span></p><p style="text-align: center;">  <br></p><center><table style="width: 90%;"><tbody><tr><td style="border: 0.5px solid black; text-align: center;"><strong><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">Document Name</span></strong></div></td><td style="border: 0.5px solid black; text-align: center;"><strong><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">Created Date</span></strong></td><td style="border: 0.5px solid black; text-align: center;"><strong><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;, &quot;Lucida Grande&quot;, sans-serif;">Last Modified On</span></strong></td><td style="border: 0.5px solid black; text-align: center;"><strong><span style="font-size: 12px; font-family: &quot;Lucida Sans Unicode&quot;,&quot;Lucida Grande&quot;, sans-serif;">Last Modified By</span></strong></td></tr>' + recordsToShowInHTML + '</tbody></table></center>';
        Map<String, String> options = new Map<String, String>();
        Api2PdfResponse pdfResponse1 = a2pClient.headlessChromeFromHtml(htmlFullContent, true, 'SummaryDocument.pdf', options);
        String linkToPage1Summary = pdfResponse1.getPdf();
        
        //Create a list to hold all links to all documents that we will merge together, the first will be the summary page
        List<String> listOfDownloadLinks = getPublicUrlsOfAttachments(listOfAttachments);
        listOfDownloadLinks.add(0, linkToPage1Summary);

        //Return the final download url of the entire document with all information requested.
        return listOfDownloadLinks;
    }


    @AuraEnabled
    public static List<String> getPublicUrlsOfAttachments(List<ContentDocumentLink> listOfAttachments){
        
        List<ContentDistribution> newContentDistRecords = new List<ContentDistribution>();
        Datetime rightNow = System.now();
        Datetime twoMinuteLaterThanNow = rightnow.addMinutes(2);

        for(ContentDocumentLink attachment : listOfAttachments){
            
            //Create a new content distribution record for the API to be able to access and merge this attachment later
            ContentDistribution contentDistibution1 = new ContentDistribution();
            contentDistibution1.name = attachment.ContentDocument.Title;
            contentDistibution1.contentVersionId = attachment.ContentDocument.LatestPublishedVersionId;
            contentDistibution1.preferencesAllowPdfDownload = true;
            contentDistibution1.preferencesAllowOriginalDownload = true;
            contentDistibution1.preferencesPasswordRequired = false;
            contentDistibution1.preferencesNotifyOnVisit = true;
            contentDistibution1.preferencesAllowViewInBrowser = false;
            contentDistibution1.preferencesExpires = true;
            contentDistibution1.expiryDate = twoMinuteLaterThanNow;
            contentDistibution1.preferencesNotifyRndtnComplete = false;

            newContentDistRecords.add(contentDistibution1);
            
        }
        
        //Insert all the new Content Distribution records created
        Database.SaveResult[] databaseResult = Database.insert(newContentDistRecords, false);
        List<Id> contentDistIdsReturned = new List<Id>();
        for(Database.SaveResult element : databaseResult){
            contentDistIdsReturned.add(element.id);
        }

        //Create a list to send the final download links of all these documents
        List<String> listOfDownloadLinks = new List<String>();

        //Select again the Content Distributions just inserted to get the ContentDownloadUrl within them that Salesforce provided at insertion
        List<ContentDistribution> recordsInsertedInSystem = [SELECT     Id, 
                                                                        ContentDownloadUrl 
                                                            FROM        ContentDistribution 
                                                            WHERE       Id IN :contentDistIdsReturned];
                                                            
        for(ContentDistribution element : recordsInsertedInSystem){
            listOfDownloadLinks.add(element.ContentDownloadUrl);
        }

        return listOfDownloadLinks;
        
    }

    @AuraEnabled
    public static String getFinalUrlForDownload(List<String> documentPublicUrls){
        
        String today = Datetime.now().format('yyyy-MM-dd');
        
        //Initialice API client
        Api2PdfClient a2pClient = new Api2PdfClient('5f027945-b58f-45c8-88dc-27f9e9fb9ecc');
        
        //Pass all the URLs of the pdfs to the API so it can merge them together
        Api2PdfResponse pdfResponse2 = a2pClient.mergePdf(documentPublicUrls, true, 'Report Documents Pending Ratification ' + today +'.pdf');
        
        String pdfUrl = pdfResponse2.getPdf();

        return pdfUrl;
        
    }

}