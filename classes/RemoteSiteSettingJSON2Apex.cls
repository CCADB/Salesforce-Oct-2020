public class RemoteSiteSettingJSON2Apex {
    
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

    public List<String> records_type_info {get;set;} 
    public List<Records> records {get;set;} 
    public List<String> field_order_type_info {get;set;} 
    public List<String> apex_schema_type_info {get;set;} 

    public RemoteSiteSettingJSON2Apex(JSONParser parser) {
        
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != JSONToken.VALUE_NULL) {
                    if (text == 'records_type_info') {
                        records_type_info = new List<String>();
                        while (parser.nextToken() != JSONToken.END_ARRAY) {
                            records_type_info.add(String.valueOf(parser));
                        }
                    } else if (text == 'records') {
                        records = new List<Records>();
                        while (parser.nextToken() != JSONToken.END_ARRAY) {
                            records.add(new Records(parser));
                        }
                    } else if (text == 'field_order_type_info') {
                        field_order_type_info = new List<String>();
                        while (parser.nextToken() != JSONToken.END_ARRAY) {
                            field_order_type_info.add(String.valueOf(parser));
                        }
                    } else if (text == 'apex_schema_type_info') {
                        apex_schema_type_info = new List<String>();
                        while (parser.nextToken() != JSONToken.END_ARRAY) {
                            apex_schema_type_info.add(String.valueOf(parser));
                        }
                    } else {
                        System.debug(LoggingLevel.WARN, 'Root consuming unrecognized property: '+text);
                        consumeObject(parser);
                    }
                }
            }
        }
    }
    
    public class Records {
        public String fullName {get;set;} 
        public List<String> url_type_info {get;set;} 
        public String url {get;set;} 
        public List<String> type_att_info {get;set;} 
        public String type_Z {get;set;} // in json: type
        public List<String> isActive_type_info {get;set;} 
        public Boolean isActive {get;set;} 
        public List<String> fullName_type_info {get;set;} 
        public List<String> field_order_type_info {get;set;} 
        public List<String> disableProtocolSecurity_type_info {get;set;} 
        public Boolean disableProtocolSecurity {get;set;} 
        public List<String> description_type_info {get;set;} 
        public Object description {get;set;} 
        public List<String> apex_schema_type_info {get;set;} 

        public Records(JSONParser parser) {
            while (parser.nextToken() != JSONToken.END_OBJECT) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != JSONToken.VALUE_NULL) {
                        if (text == 'fullName') {
                            fullName = parser.getText();
                        } else if (text == 'url_type_info') {
                            url_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                url_type_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'url') {
                            url = parser.getText();
                        } else if (text == 'type_att_info') {
                            type_att_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                type_att_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'type') {
                            type_Z = parser.getText();
                        } else if (text == 'isActive_type_info') {
                            isActive_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                isActive_type_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'isActive') {
                            isActive = parser.getBooleanValue();
                        } else if (text == 'fullName_type_info') {
                            fullName_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                fullName_type_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'field_order_type_info') {
                            field_order_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                field_order_type_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'disableProtocolSecurity_type_info') {
                            disableProtocolSecurity_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                disableProtocolSecurity_type_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'disableProtocolSecurity') {
                            disableProtocolSecurity = parser.getBooleanValue();
                        } else if (text == 'description_type_info') {
                            description_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                description_type_info.add(String.valueOf(parser));
                            }
                        } else if (text == 'description') {
                            //description = new Object(parser);
                        } else if (text == 'apex_schema_type_info') {
                            apex_schema_type_info = new List<String>();
                            while (parser.nextToken() != JSONToken.END_ARRAY) {
                                apex_schema_type_info.add(String.valueOf(parser));
                            }
                        } else {
                            System.debug(LoggingLevel.WARN, 'Records consuming unrecognized property: '+text);
                            consumeObject(parser);
                        }
                    }
                }
            }
        }
    }
    
    
    public static RemoteSiteSettingJSON2Apex parse(String json) {
        return new RemoteSiteSettingJSON2Apex(System.JSON.createParser(json));
    }
}