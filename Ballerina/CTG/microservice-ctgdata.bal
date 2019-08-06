import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-ctgdata",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

@docker:Expose{}
listener http:Listener httpListener = new(9093);


// Mock server URL
http:Client ctgDataEndpoint = new("http://34.77.0.121:8080");

service retrait on new http:Listener(9093) {
    resource function data (http:Caller caller, http:Request request){
        
        http:Response response_toclient = new;
        
        var mock_response = ctgDataEndpoint->get("/mocks/retrait/controle");

        if (mock_response is http:Response) {
            var retraitdata = mock_response.getJsonPayload();
            if (retraitdata is json) {
                response_toclient.setJsonPayload(untaint retraitdata);    
            } else {
            io:println("Invalid payload received:" , retraitdata.reason());
            }
        } else {
        io:println("Error when calling the backend: ", mock_response.reason());
        }
        
        var result = caller->respond(response_toclient);        
    }
}