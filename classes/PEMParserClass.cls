/*
    Description: PEM Parser class is used to Parse PEM Info.
    
    firstSeenTimestamp and lastSeenTimestamp commented because 
    it is giving every time differnt times for some of root and intermediate certs.
*/

public class PEMParserClass {
    
    public String id;
    public String serialNumber;
    public String version;
    public String signatureAlgorithm;
    public Issuer issuer;
    public Validity validity;
    public Subject subject;
    public Key key;
    public X509v3Extensions x509v3Extensions;
    public String x509v3BasicConstraints;
    public Boolean ca;
    public ValidationInfo validationInfo;
    //public String firstSeenTimestamp;
    //public String lastSeenTimestamp;
    public Hashes hashes;
    //public String Raw;
    public String ciscoUmbrellaRank;
    public cls_mozillaPolicyV2_5 mozillaPolicyV2_5;

    
    public class Validity {
        public String notBefore;
        public String notAfter;
    }

    public class ValidationInfo {
        public cls_Android Android;
        public cls_Apple Apple;
        public cls_Microsoft Microsoft;
        public cls_Mozilla Mozilla;
        public cls_Ubuntu Ubuntu;
    }

    public class cls_Apple {
        public Boolean isValid;
    }

    public class cls_Android {
        public Boolean isValid;
    }

    public class cls_Microsoft {
        public Boolean isValid;
    }

    public class cls_Mozilla {
        public Boolean isValid;
    }
    
    public class cls_Ubuntu {
        public Boolean isValid;
    }
    
    public class Issuer {
        public String id;
        public List<String> c;
        public List<String> o;
        public List<String> ou;
        public String cn;
    }

    public class Hashes {
        public String sha1;
        public String sha256;
        public String spkisha256;
        public String pinsha256;
        public String subjectspkisha256;
    }

    public class X509v3Extensions {
        public String authorityKeyId;
        public String subjectKeyId;
        public List<String> keyUsage;
        public List<string> extendedKeyUsage;
        public List<string> extendedKeyUsageOID;
        public List<string> subjectAlternativeName;
        public List<String> crlDistributionPoint;
        public List<String> policyIdentifiers;
        public Boolean isTechnicallyConstrained;
    }

    public class Subject {
        public List<String> c;
        public List<String> o;
        public List<String> ou;
        public String cn;
    }

    public class Key {
        public String alg;
        public String size;
        public String exponent;
    }

    public class cls_mozillaPolicyV2_5 {
        public boolean IsTechnicallyConstrained;
    }

    public static PEMParserClass parse(String json) {
        return (PEMParserClass) System.JSON.deserialize(json, PEMParserClass.class);
    }
}