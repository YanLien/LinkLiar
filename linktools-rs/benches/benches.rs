use criterion::{black_box, criterion_group, criterion_main, Criterion};
use linktools::{MAC, OUI, VendorDatabase};

fn mac_parsing_benchmark(c: &mut Criterion) {
    let input = "00:03:93:12:34:56";
    
    c.bench_function("mac parse", |b| {
        b.iter(|| {
            MAC::parse(black_box(input)).unwrap()
        })
    });
}

fn oui_lookup_benchmark(c: &mut Criterion) {
    let db = VendorDatabase::default();
    let oui = OUI::parse("000393").unwrap();
    
    c.bench_function("oui lookup", |b| {
        b.iter(|| {
            db.lookup(black_box(&oui))
        })
    });
}

fn random_mac_benchmark(c: &mut Criterion) {
    c.bench_function("random local mac", |b| {
        b.iter(|| {
            MAC::random_local()
        })
    });
}

fn random_vendor_mac_benchmark(c: &mut Criterion) {
    let db = VendorDatabase::default();
    
    c.bench_function("random vendor mac", |b| {
        b.iter(|| {
            db.random_mac_for_vendor("apple")
        })
    });
}

criterion_group!(
    benches,
    mac_parsing_benchmark,
    oui_lookup_benchmark,
    random_mac_benchmark,
    random_vendor_mac_benchmark,
);

criterion_main!(benches);
