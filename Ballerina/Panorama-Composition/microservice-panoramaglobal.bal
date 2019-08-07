import ballerina/http;
import ballerina/log;
import ballerina/io;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-panoramaglobal",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

// Service endpoint
@docker:Expose{}
listener http:Listener PCompositionMS = new(9097);

// Client endpoint to communicate with User MS
// http:Client userInfosEndpoint = new("http://localhost:9091/user");
http:Client userInfosEndpoint = new("http://ballerina-getuser:80/user");

// Client endpoint to communicate with Visualiser Panorama MS
// http:Client panoramaEpargneEndpoint = new("http://localhost:9095/panorama");
http:Client panoramaEpargneEndpoint = new("http://ballerina-visualiser:80/panorama");

// Client endpoint to communicate with WS Account MS
// http:Client panoramaCreditEndpoint = new("http://localhost:9096/panorama");
http:Client panoramaCreditEndpoint = new("http://ballerina-wsaccount:80/panorama");

service panorama on PCompositionMS {

    @http:ResourceConfig {methods: ["GET"]}
    resource function afficherPanorama (http:Caller caller, http:Request request){
    
        http:Response zePanoramaOUT = new;  
        
        map<string> params = request.getQueryParams(); 
        
        string pswSaisi = <string>params["pswSaisi"];
        string numeroDossier_string = <string>params["numeroDossier"];
        string numeroFoyer_string = <string>params["numeroFoyer"];
        string codeComposant_string = <string>params["codeComposant"];
        string numeroClient_string = <string>params["numeroClient"];

        int numeroDossier = <int>int.convert(numeroDossier_string);
        int numeroFoyer = <int>int.convert(numeroFoyer_string);
        int codeComposant = <int>int.convert(codeComposant_string);
        int numeroClient = <int>int.convert(numeroClient_string);


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

        int usernumvend = <int>user_infos_payload.OUTusernumvend; 
        int usermat = <int>user_infos_payload.OUTusermat;
        int agconf = <int>user_infos_payload.OUTagconf;

        //Getting Panorama Epargne
        http:Response panoramaEpargneEndpoint_response = new;
        var panorama_epargne = panoramaEpargneEndpoint->get("/epargne?OUTusernumvend="+untaint usernumvend+"&OUTusermat="+untaint usermat+"&OUTagconf="+untaint agconf);
        if (panorama_epargne is http:Response) {
            var panorama_epargne_payload_init = <json>panorama_epargne.getJsonPayload();
            // if (dossier_infos_payload_init is json) {
                panoramaEpargneEndpoint_response.setJsonPayload(untaint panorama_epargne_payload_init); 
            // } else {
            //     io:println("Invalid payload received:" , dossier_infos_payload_init.reason());
            // }
        } else {
            io:println("Error when calling the backend: ", panorama_epargne.reason());
        }

        var panorama_epargne_payload = <json>panoramaEpargneEndpoint_response.getJsonPayload();    

        //Getting Panorama Credit
        http:Response panoramaCreditEndpoint_response = new;
        var panorama_credit = panoramaCreditEndpoint->get("/credit?OUTusernumvend="+untaint usernumvend+"&OUTusermat="+untaint usermat+"&OUTagconf="+untaint agconf);
        if (panorama_credit is http:Response) {
            var panorama_credit_payload_init = <json>panorama_credit.getJsonPayload();
            // if (dossier_infos_payload_init is json) {
                panoramaCreditEndpoint_response.setJsonPayload(untaint panorama_credit_payload_init); 
            // } else {
            //     io:println("Invalid payload received:" , dossier_infos_payload_init.reason());
            // }
        } else {
            io:println("Error when calling the backend: ", panorama_credit.reason());
        }

        var panorama_credit_payload = <json>panoramaCreditEndpoint_response.getJsonPayload();   

        
        //Setting Output
        json outputsetter = {};
     
        outputsetter.numeroDossier = numeroDossier;
        outputsetter.numeroFoyer = numeroFoyer;
        outputsetter.codeComposant = codeComposant;
        outputsetter.numeroClient = numeroClient;
        outputsetter.password = pswSaisi;
        outputsetter.foyer = panorama_epargne_payload.output.foyer;
        outputsetter.carte = panorama_epargne_payload.output.carte;
        outputsetter.epargne = panorama_epargne_payload.output.epargne;
        outputsetter.credit = panorama_credit_payload;


        zePanoramaOUT.setJsonPayload(untaint outputsetter);    
        var result = caller->respond(zePanoramaOUT);

    }
}

