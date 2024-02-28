export interface VetStationList {
  vetStations: VetStation[]
}

export interface VetStation {
  id: number
  name: string
  contactNumber: string
  isInOffice: boolean
  isOnField: boolean
  parking: boolean
  wheelchair: boolean
  wifi: boolean
}
