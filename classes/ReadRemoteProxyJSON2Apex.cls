public class ReadRemoteProxyJSON2Apex {
    public static void consumeObject(JSONParser parser) {
        Integer depth = 0;
        do {
            JSONToken curr = parser.getCurrentToken();
            if (curr == JSONToken.START_OBJECT || 
                curr == JSONToken.START_ARRAY) {
                depth++;
            } else if (curr == JSONToken.END_OBJECT ||
                curr == JSONToken.END_ARRAY) {
                depth--;
            }
        } while (depth > 0 && parser.nextToken() != null);
    }

    public Integer size {get;set;} 
    public Integer totalSize {get;set;} 
    public Boolean done {get;set;} 
    public Object queryLocator {get;set;} 
    public String entityTypeName {get;set;} 
    public List<Records> records {get;set;} 

    public ReadRemoteProxyJSON2Apex(JSONParser parser) {
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != JSONToken.VALUE_NULL) {
                    if (text == 'size') {
                        size = parser.getIntegerValue();
                    } else if (text == 'totalSize') {
                        totalSize = parser.getIntegerValue();
                    } else if (text == 'done') {
                        done = parser.getBooleanValue();
                    } else if (text == 'queryLocator') {
                        //queryLocator = new Object(parser);
                    } else if (text == 'entityTypeName') {
                        entityTypeName = parser.getText();
                    } else if (text == 'records') {
                        records = new List<Records>();
                        while (parser.nextToken() != JSONToken.END_ARRAY) {
                            records.add(new Records(parser));
                        }
                    } else {
                        System.debug(LoggingLevel.WARN, 'Root consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public class Attributes {
        public String type_Z {get;set;} // in json: type
        public String url {get;set;} 

        public Attributes(JSONParser parser) {
            while (parser.nextToken() != JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != JSONToken.VALUE_NULL) {
                        if (text == 'type') {
                            type_Z = parser.getText();
                        } else if (text == 'url') {
                            url = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Attributes consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    public class Records {
        public Attributes attributes {get;set;} 
        public String EndpointUrl {get;set;} 

        public Records(JSONParser parser) {
            while (parser.nextToken() != JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != JSONToken.VALUE_NULL) {
                        if (text == 'attributes') {
                            attributes = new Attributes(parser);
                        } else if (text == 'EndpointUrl') {
                            EndpointUrl = parser.getText();
                        } else {
                            System.debug(LoggingLevel.WARN, 'Records consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    
    public static ReadRemoteProxyJSON2Apex parse(String json) {
        return new ReadRemoteProxyJSON2Apex(System.JSON.createParser(json));
    }
}