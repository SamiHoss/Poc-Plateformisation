import ballerina/http;
import ballerina/io;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-visualiserpanorama",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

@docker:Expose{}
listener http:Listener httpListener = new(9095);


// Mock server URL
http:Client panoramaEpargneEndpoint = new("http://34.77.0.121:8080");

service panorama on new http:Listener(9095) {
    resource function epargne (http:Caller caller, http:Request request){
        
        http:Response response_toclient = new;

        map<string> params = request.getQueryParams(); 
        
        int OUTusernumvend = <int>int.convert(<string>params["OUTusernumvend"]);
        int OUTusermat = <int>int.convert(<string>params["OUTusermat"]);
        int OUTagconf = <int>int.convert(<string>params["OUTagconf"]);

        if (OUTusernumvend > 0 && OUTusermat > 0 && OUTagconf > 0) {
                        
            var mock_response = panoramaEpargneEndpoint->get("/mocks/panorama/epargne");

            if (mock_response is http:Response) {
                var panoramaEpargne = mock_response.getJsonPayload();
                if (panoramaEpargne is json) {
                    response_toclient.setJsonPayload(untaint panoramaEpargne);    
                } else {
                io:println("Invalid payload received:" , panoramaEpargne.reason());
                }
            } else {
            io:println("Error when calling the backend: ", mock_response.reason());
            }
            
        } else {
            io:println("Imcomplete user data");
        }        

        var result = caller->respond(response_toclient);        
    }
}