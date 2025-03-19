export interface VetStationList {
  vetStations: VetStation[]
}

export interface VetStation {
  id: number
  name: string
  stationImage: string;
  contactNumber: string
  inOffice: boolean
  onField: boolean
  parking: boolean
  wheelchair: boolean
  wifi: boolean
}
