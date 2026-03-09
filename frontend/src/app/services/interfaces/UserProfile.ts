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
  isAdmin: boolean;
  isVisitor: boolean;
  birthDate: string;
  username: string | null;
  password: string | null;
  cityId: number | null;
  verified: boolean;
  roleId: number | null;
  role: string;
  permissionLevel: number;
  employeeId: number | null;
  vetStationId: number | null;
}
