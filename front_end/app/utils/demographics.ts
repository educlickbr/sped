export const getPcdCount = (stats: any[]) => {
    if (!stats) return 0;
    const target = stats.find(i => {
        const lbl = String(i.label).trim().toLowerCase();
        return ['true', 'sim', 's', 'yes', '1'].includes(lbl);
    });
    return target?.qtd || 0;
};

export const calculateAgeDistribution = (birthdates: string[] | null) => {
    if (!birthdates || !birthdates.length) return [];

    // Buckets
    const buckets: Record<string, number> = {
        '< 18': 0, '18-24': 0, '25-34': 0, '35-44': 0, '45-59': 0, '60+': 0
    };

    const today = new Date();

    birthdates.forEach((dateStr) => {
        if (!dateStr) return;
        
        let birthDate: Date | null = null;
        
        // Handle various formats
        // 1. ISO Timestamp (YYYY-MM-DDTHH:mm:ss) or YYYY-MM-DD
        if (dateStr.includes('-')) {
             const parts = dateStr.split('T');
             const cleanDate = parts[0]; 
             if (cleanDate && /^\d{4}-\d{2}-\d{2}$/.test(cleanDate)) {
                 birthDate = new Date(cleanDate);
             }
        }
        // 2. Local DD/MM/YYYY
        else if (dateStr.includes('/')) {
             const parts = dateStr.split('/');
             if (parts.length === 3) {
                 const [day, month, year] = parts;
                 // Ensure we have 4 digit year
                 if (year && month && day && year.length === 4) {
                      birthDate = new Date(`${year}-${month}-${day}`);
                 }
             }
        }

        if (birthDate && !isNaN(birthDate.getTime())) {
            let age = today.getFullYear() - birthDate.getFullYear();
            const m = today.getMonth() - birthDate.getMonth();
            if (m < 0 || (m === 0 && today.getDate() < birthDate.getDate())) {
                age--;
            }

            if (age < 18) buckets['< 18'] = (buckets['< 18'] || 0) + 1;
            else if (age <= 24) buckets['18-24'] = (buckets['18-24'] || 0) + 1;
            else if (age <= 34) buckets['25-34'] = (buckets['25-34'] || 0) + 1;
            else if (age <= 44) buckets['35-44'] = (buckets['35-44'] || 0) + 1;
            else if (age <= 59) buckets['45-59'] = (buckets['45-59'] || 0) + 1;
            else buckets['60+'] = (buckets['60+'] || 0) + 1;
        }
    });

    return Object.entries(buckets)
        .map(([faixa, qtd]) => ({ faixa, qtd }))
        .filter(i => i.qtd > 0);
};
