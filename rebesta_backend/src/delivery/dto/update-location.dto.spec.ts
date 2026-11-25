import { validate } from 'class-validator';
import { UpdateLocationDto } from './update-location.dto';

describe('UpdateLocationDto', () => {
  const makeDto = (latitude: unknown, longitude: unknown) => {
    const dto = new UpdateLocationDto();
    dto.latitude = latitude as number;
    dto.longitude = longitude as number;
    return dto;
  };

  it.each([
    [0, 0],
    [90, 180],
    [-90, -180],
    [12.345, 76.543],
  ])('accepts valid coordinates %p %p', async (latitude, longitude) => {
    expect(await validate(makeDto(latitude, longitude))).toHaveLength(0);
  });

  it.each([
    [91, 0],
    [-91, 0],
    [0, 181],
    [0, -181],
    [Number.NaN, 0],
    [0, Number.POSITIVE_INFINITY],
  ])('rejects invalid coordinates %p %p', async (latitude, longitude) => {
    expect(await validate(makeDto(latitude, longitude))).not.toHaveLength(0);
  });
});
