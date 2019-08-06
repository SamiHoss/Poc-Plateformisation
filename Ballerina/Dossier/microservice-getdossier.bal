import ballerina/http;
import ballerina/io;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-dossierinfos",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

@docker:Expose{}
listener http:Listener httpListener = new(9092);


// Mock server URL
http:Client dossierInfosEndpoint = new("http://34.77.0.121:8080");

service dossier on new http:Listener(9092) {
    resource function infos (http:Caller caller, http:Request request){
        
        http:Response response_toclient = new;
        
        var mock_response = dossierInfosEndpoint->get("/mocks/dossierclient");

        if (mock_response is http:Response) {
            var dossierinfos = mock_response.getJsonPayload();
            if (dossierinfos is json) {
                response_toclient.setJsonPayload(untaint dossierinfos);    
            } else {
            io:println("Invalid payload received:" , dossierinfos.reason());
            }
        } else {
        io:println("Error when calling the backend: ", mock_response.reason());
        }
        
        var result = caller->respond(response_toclient);        
    }
}