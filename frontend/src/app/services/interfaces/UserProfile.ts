export interface UserProfile {
  id: number;
  firstName: string | null;
  lastName: string | null;
  email: string | null;
  phone: string | null;
  isVet: boolean;
  isNurse: boolean;
  isBarber: boolean;
  isMainVet: boolean;
  isBasicUser: boolean;
  isVisitor: boolean;
  birthDate: string;
  username: string | null;
  password: string | null;
  cityId: number | null;
}
