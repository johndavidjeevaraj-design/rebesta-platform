import 'dotenv/config';
import axios from 'axios';
import { supabase } from '../src/supabase';

async function geocode(text: string) {
  const response = await axios.post(
    'https://api.openrouteservice.org/geocoding/v1/search',
    { text, size: 1 },
    {
      headers: {
        Authorization: process.env.ORS_API_KEY as string,
        'Content-Type': 'application/json',
      },
      timeout: 5000,
    },
  );

  const f = response.data?.results?.[0];
  if (!f?.geometry?.coordinates) return null;

  return {
    latitude: Number(f.geometry.coordinates[1]),
    longitude: Number(f.geometry.coordinates[0]),
    label: f.properties?.label as string,
  };
}

async function main() {
  const { data: restaurants, error } = await supabase
    .from('restaurants')
    .select('*')
    .or('latitude.is.null,longitude.is.null');

  if (error) throw error;

  if (!restaurants || restaurants.length === 0) {
    console.log('Nothing to backfill ✅');
    return;
  }

  console.log(`Found ${restaurants.length} restaurant(s) missing coordinates`);

  for (const r of restaurants) {
    const fullAddress = [r.address, r.city, r.state, r.pincode]
      .filter(Boolean)
      .join(', ');

    console.log(`\n📍 ${fullAddress}`);

    const result = await geocode(fullAddress);

    if (!result) {
      console.log('  ⚠️  No result — set manually in Supabase');
      continue;
    }

    const { error: updateError } = await supabase
      .from('restaurants')
      .update({
        latitude: result.latitude,
        longitude: result.longitude,
      })
      .eq('id', r.id);

    if (updateError) {
      console.log('  ❌ Update failed:', updateError.message);
    } else {
      console.log(
        `  ✅ ${result.label} → ${result.latitude}, ${result.longitude}`,
      );
    }

    // Stay under ORS rate limits
    await new Promise((res) => setTimeout(res, 1100));
  }

  console.log('\nDone. Re-run the SQL check to verify.');
}

main().catch(console.error);