import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-controlersaisie",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

// Service endpoint
@docker:Expose{}
listener http:Listener CompositionMS = new(9094);

// Client endpoint to communicate with User MS
// http:Client userInfosEndpoint = new("http://localhost:9091/user");
http:Client userInfosEndpoint = new("http://ballerina-getuser:80/user");

// Client endpoint to communicate with Dossier MS
// http:Client dossierInfosEndpoint = new("http://localhost:9092/dossier");
http:Client dossierInfosEndpoint = new("http://ballerina-getdossier:80/dossier");

// Client endpoint to communicate with CTG MS
// http:Client ctgDataEndpoint = new("http://localhost:9093/retrait");
http:Client ctgDataEndpoint = new("http://ballerina-ctgdata:80/retrait");

// Mock server URL
http:Client ctgRetraitValidator = new("http://34.77.0.121:8093");

service retraitcsl on CompositionMS {

    @http:ResourceConfig {methods: ["GET"]}
    resource function controlerSaisie (http:Caller caller, http:Request request){
    
        http:Response zeRetraitLivretOUT = new;  
        map<string> params = request.getQueryParams(); 
        string montant_string = <string>params["montant"];
        int montant = <int>int.convert(montant_string);  

        //Getting User Infos
        http:Response userInfosEndpoint_response = new;
        var user_infos = userInfosEndpoint->get("/infos");
        if (user_infos is http:Response) {
            var user_infos_payload_init = <json>user_infos.getJsonPayload();
            userInfosEndpoint_response.setJsonPayload(untaint user_infos_payload_init); 
        } else {
            io:println("Error when calling the backend: ", user_infos.reason());
        }

        var user_infos_payload = <json>userInfosEndpoint_response.getJsonPayload(); 

        //Getting Dossier Infos
        http:Response dossierInfosEndpoint_response = new;
        var dossier_infos = dossierInfosEndpoint->get("/infos");
        if (dossier_infos is http:Response) {
            var dossier_infos_payload_init = <json>dossier_infos.getJsonPayload();
            // if (dossier_infos_payload_init is json) {
                dossierInfosEndpoint_response.setJsonPayload(untaint dossier_infos_payload_init); 
            // } else {
            //     io:println("Invalid payload received:" , dossier_infos_payload_init.reason());
            // }
        } else {
            io:println("Error when calling the backend: ", dossier_infos.reason());
        }

        var dossier_infos_payload = <json>dossierInfosEndpoint_response.getJsonPayload();    

        //Getting Empty CTG Data 
        http:Response ctgDataEndpoint_response = new;
        var ctg_data = ctgDataEndpoint->get("/data");
        if (ctg_data is http:Response) {
            var ctg_data_payload = <json>ctg_data.getJsonPayload();
            // if (ctg_data_payload is json) {
                ctg_data_payload.input.user.usernumvend = user_infos_payload.OUTusernumvend; 
                ctg_data_payload.input.user.usernumvend = user_infos_payload.OUTusernumvend;
                ctg_data_payload.input.user.usermat = user_infos_payload.OUTusermat;
                ctg_data_payload.input.user.userctrl = user_infos_payload.OUTuserctrl;

                ctg_data_payload.input.cdaction = "2";
                ctg_data_payload.input.page1.donord.donord = "TITU";
                ctg_data_payload.input.page1.ribtitu.saisi = true;
                ctg_data_payload.input.page1.retrait.retmode = "VRMT";
                ctg_data_payload.input.page1.retrait.montant = montant;

                ctg_data_payload.input.cdtitre = dossier_infos_payload.OUTdossier.cdtitre;
                ctg_data_payload.input.clien.numcli = dossier_infos_payload.OUTclient.numcli;
                ctg_data_payload.input.clien.cdcps = dossier_infos_payload.OUTclient.cdcps;
                ctg_data_payload.input.clien.cliaptitude = dossier_infos_payload.OUTclient.apttitu;
                ctg_data_payload.input.clien.titupsa = dossier_infos_payload.OUTclient.titupsa;
                ctg_data_payload.input.numdoss = dossier_infos_payload.OUTdossier.numdoss;
                ctg_data_payload.input.dossposactcd = dossier_infos_payload.OUTdossier.dospos;
                ctg_data_payload.input.page1.donord.dosigle = dossier_infos_payload.OUTclient.titusigle;
                ctg_data_payload.input.page1.donord.donompre = dossier_infos_payload.OUTclient.titunompre;
                ctg_data_payload.input.page1.ribtitu = dossier_infos_payload.OUTdossier.ribdossier;

                ctgDataEndpoint_response.setJsonPayload(untaint ctg_data_payload);   
            // } else {
            //     io:println("Invalid payload received:" , ctg_data_payload.reason());
            // }
        } else {
            io:println("Error when calling the backend: ", ctg_data.reason());
        }

        var ctg_data_payload_for_control = <json>ctgDataEndpoint_response.getJsonPayload();

        //Sending CTG Data to Backend for control
        http:Request control_request = new;
        // if (ctg_data_payload_for_control is json) {
            control_request.setPayload(untaint ctg_data_payload_for_control);
        // } else {
        //     io:println("Invalid payload received:" , ctg_data_payload_for_control.reason());
        // }
        
        http:Response ctgRetraitValidator_response = new;
        var ctg_control = ctgRetraitValidator->post("/ctgcontrol", control_request);
        
        //Setting Output
        if (ctg_control is http:Response) {
            var ctg_control_payload_init = <json>ctg_control.getJsonPayload();
            ctgRetraitValidator_response.setJsonPayload(untaint ctg_control_payload_init);

        } else {
            io:println("Error when calling the backend: ", ctg_control.reason());
        }

        var ctg_control_payload = <json>ctgRetraitValidator_response.getJsonPayload(); 

        json outputsetter = {};

        outputsetter.montantRetrait = ctg_control_payload.input.page1.retrait.montant;
        outputsetter.ribCompte = ctg_control_payload.input.page1.ribtitu.numeroCompte;
        outputsetter.ribLieu = ctg_control_payload.input.page1.ribtitu.lieuBanque;
        outputsetter.errmnt = ctg_control_payload.output.page1.errmnt;
        outputsetter.codeAlerte = ctg_control_payload.output.cdalerte;
        outputsetter.messageAlerte = ctg_control_payload.output.messageAlerte;
        outputsetter.zeIdOperation = ctg_control_payload.output.consultation.idodermaj;

        zeRetraitLivretOUT.setJsonPayload(untaint outputsetter);    
        var result = caller->respond(zeRetraitLivretOUT);

    }

    @http:ResourceConfig {methods: ["GET"]}
    resource function validerSaisie (http:Caller caller, http:Request request){
    
        http:Response zeRetraitLivretOUT = new;  
        map<string> params = request.getQueryParams(); 
        string montant_string = <string>params["montant"];
        int montant = <int>int.convert(montant_string);  

        //Getting User Infos
        http:Response userInfosEndpoint_response = new;
        var user_infos = userInfosEndpoint->get("/infos");
        if (user_infos is http:Response) {
            var user_infos_payload_init = <json>user_infos.getJsonPayload();
            userInfosEndpoint_response.setJsonPayload(untaint user_infos_payload_init); 
        } else {
            io:println("Error when calling the backend: ", user_infos.reason());
        }

        var user_infos_payload = <json>userInfosEndpoint_response.getJsonPayload(); 

        //Getting Dossier Infos
        http:Response dossierInfosEndpoint_response = new;
        var dossier_infos = dossierInfosEndpoint->get("/infos");
        if (dossier_infos is http:Response) {
            var dossier_infos_payload_init = <json>dossier_infos.getJsonPayload();
            // if (dossier_infos_payload_init is json) {
                dossierInfosEndpoint_response.setJsonPayload(untaint dossier_infos_payload_init); 
            // } else {
            //     io:println("Invalid payload received:" , dossier_infos_payload_init.reason());
            // }
        } else {
            io:println("Error when calling the backend: ", dossier_infos.reason());
        }

        var dossier_infos_payload = <json>dossierInfosEndpoint_response.getJsonPayload();    

        //Getting Empty CTG Data 
        http:Response ctgDataEndpoint_response = new;
        var ctg_data = ctgDataEndpoint->get("/data");
        if (ctg_data is http:Response) {
            var ctg_data_payload = <json>ctg_data.getJsonPayload();
            // if (ctg_data_payload is json) {
                ctg_data_payload.input.user.usernumvend = user_infos_payload.OUTusernumvend; 
                ctg_data_payload.input.user.usernumvend = user_infos_payload.OUTusernumvend;
                ctg_data_payload.input.user.usermat = user_infos_payload.OUTusermat;
                ctg_data_payload.input.user.userctrl = user_infos_payload.OUTuserctrl;

                ctg_data_payload.input.cdaction = "2";
                ctg_data_payload.input.page1.donord.donord = "TITU";
                ctg_data_payload.input.page1.ribtitu.saisi = true;
                ctg_data_payload.input.page1.retrait.retmode = "VRMT";
                ctg_data_payload.input.page1.retrait.montant = montant;

                ctg_data_payload.input.cdtitre = dossier_infos_payload.OUTdossier.cdtitre;
                ctg_data_payload.input.clien.numcli = dossier_infos_payload.OUTclient.numcli;
                ctg_data_payload.input.clien.cdcps = dossier_infos_payload.OUTclient.cdcps;
                ctg_data_payload.input.clien.cliaptitude = dossier_infos_payload.OUTclient.apttitu;
                ctg_data_payload.input.clien.titupsa = dossier_infos_payload.OUTclient.titupsa;
                ctg_data_payload.input.numdoss = dossier_infos_payload.OUTdossier.numdoss;
                ctg_data_payload.input.dossposactcd = dossier_infos_payload.OUTdossier.dospos;
                ctg_data_payload.input.page1.donord.dosigle = dossier_infos_payload.OUTclient.titusigle;
                ctg_data_payload.input.page1.donord.donompre = dossier_infos_payload.OUTclient.titunompre;
                ctg_data_payload.input.page1.ribtitu = dossier_infos_payload.OUTdossier.ribdossier;

                ctgDataEndpoint_response.setJsonPayload(untaint ctg_data_payload);   
            // } else {
            //     io:println("Invalid payload received:" , ctg_data_payload.reason());
            // }
        } else {
            io:println("Error when calling the backend: ", ctg_data.reason());
        }

        var ctg_data_payload_for_control = <json>ctgDataEndpoint_response.getJsonPayload();

        //Sending CTG Data to Backend for control
        http:Request validation_request = new;
        // if (ctg_data_payload_for_control is json) {
            validation_request.setPayload(untaint ctg_data_payload_for_control);
        // } else {
        //     io:println("Invalid payload received:" , ctg_data_payload_for_control.reason());
        // }
        
        http:Response ctgRetraitValidator_response = new;
        var ctg_control = ctgRetraitValidator->post("/ctgvalidation", validation_request);
        
        //Setting Output
        if (ctg_control is http:Response) {
            var ctg_control_payload_init = <json>ctg_control.getJsonPayload();
            ctgRetraitValidator_response.setJsonPayload(untaint ctg_control_payload_init);

        } else {
            io:println("Error when calling the backend: ", ctg_control.reason());
        }

        var ctg_control_payload = <json>ctgRetraitValidator_response.getJsonPayload(); 

        json outputsetter = {};

        outputsetter.montantRetrait = ctg_control_payload.input.page1.retrait.montant;
        outputsetter.ribCompte = ctg_control_payload.input.page1.ribtitu.numeroCompte;
        outputsetter.ribLieu = ctg_control_payload.input.page1.ribtitu.lieuBanque;
        outputsetter.errmnt = ctg_control_payload.output.page1.errmnt;
        outputsetter.codeAlerte = ctg_control_payload.output.cdalerte;
        outputsetter.messageAlerte = ctg_control_payload.output.messageAlerte;
        outputsetter.zeIdOperation = ctg_control_payload.output.consultation.idodermaj;

        zeRetraitLivretOUT.setJsonPayload(untaint outputsetter);    
        var result = caller->respond(zeRetraitLivretOUT);

    }
}

