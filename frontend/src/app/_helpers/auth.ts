export class AutentifikacijaHelper {

  static setLoginInfo(x: LoginInformacije):void
  {
    if (x==null)
      x = new LoginInformacije();
    localStorage.setItem("autentifikacija-token", JSON.stringify(x));
  }

  static getLoginInfo():LoginInformacije
  {
      let x: any = localStorage.getItem("autentifikacija-token");
      if (x==="")
        return new LoginInformacije();

      try {
        let loginInformacije:LoginInformacije = JSON.parse(x);
        if (loginInformacije==null)
          return new LoginInformacije();
        return loginInformacije;
      }
      catch (e)
      {
        return new LoginInformacije();
      }
  }
}


export class LoginInformacije {
    autentifikacijaToken:        AutentifikacijaToken|null=null;
    isLogiran:                   boolean=false;
  }
  
  export interface AutentifikacijaToken {
    id:                   number;
    vrijednost:           string;
    korisnickiNalogId:    number;
    korisnickiNalog:      KorisnickiNalog;
    vrijemeEvidentiranja: Date;
    ipAdresa:             string;
  }
  
  export interface KorisnickiNalog {
    id:                 number;
    korisnickoIme:      string;
    slika_korisnika:    string;
    isNastavnik:        boolean;
    isStudent:          boolean;
    isAdmin:            boolean;
    isProdekan:         boolean;
    isDekan:            boolean;
    isStudentskaSluzba: boolean;
    defaultOpstinaId:   number;
  }
  