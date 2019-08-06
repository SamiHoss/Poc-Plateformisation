import ballerina/http;
import ballerina/io;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-userinfos",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

@docker:Expose{}
listener http:Listener httpListener = new(9091);

// Mock server URL
http:Client userInfosEndpoint = new("http://34.77.0.121:8080");

service user on new http:Listener(9091) {
    resource function infos (http:Caller caller, http:Request request){
        
        http:Response response_toclient = new;
        
        var mock_response = userInfosEndpoint->get("/mocks/utilisateur");

        if (mock_response is http:Response) {
            var userinfos = mock_response.getJsonPayload();
            if (userinfos is json) {
                response_toclient.setJsonPayload(untaint userinfos);    
            } else {
            io:println("Invalid payload received:" , userinfos.reason());
            }
        } else {
        io:println("Error when calling the backend: ", mock_response.reason());
        }
        
        var result = caller->respond(response_toclient);        
    }
}