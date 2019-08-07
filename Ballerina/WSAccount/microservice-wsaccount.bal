import ballerina/http;
import ballerina/io;
import ballerinax/docker;

@docker:Config {
    registry:"samihoss",
    name:"ballerina-wsaccountpanorama",
    tag:"latest",
    push: true,
    username:"samihoss",
    password:"Inpt@2014" 
}

@docker:Expose{}
listener http:Listener httpListener = new(9096);


// Mock server URL
http:Client panoramaCreditEndpoint = new("http://34.77.0.121:8080");

service panorama on new http:Listener(9096) {
    resource function credit (http:Caller caller, http:Request request){
        
        http:Response response_toclient = new;

        map<string> params = request.getQueryParams(); 
        
        int OUTusernumvend = <int>int.convert(<string>params["OUTusernumvend"]);
        int OUTusermat = <int>int.convert(<string>params["OUTusermat"]);
        int OUTagconf = <int>int.convert(<string>params["OUTagconf"]);

        if (OUTusernumvend > 0 && OUTusermat > 0 && OUTagconf > 0) {

            var mock_response = panoramaCreditEndpoint->get("/mocks/panorama/credit");

            if (mock_response is http:Response) {
                var panoramaCredit = mock_response.getJsonPayload();
                if (panoramaCredit is json) {
                    response_toclient.setJsonPayload(untaint panoramaCredit);    
                } else {
                io:println("Invalid payload received:" , panoramaCredit.reason());
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