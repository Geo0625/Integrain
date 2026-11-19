<?php

namespace Config;

use CodeIgniter\Config\BaseConfig;
use CodeIgniter\Validation\StrictRules\CreditCardRules;
use CodeIgniter\Validation\StrictRules\FileRules;
use CodeIgniter\Validation\StrictRules\FormatRules;
use CodeIgniter\Validation\StrictRules\Rules;

class Validation extends BaseConfig
{
    // --------------------------------------------------------------------
    // Setup
    // --------------------------------------------------------------------

    /**
     * Stores the classes that contain the
     * rules that are available.
     *
     * @var list<string>
     */
    public array $ruleSets = [
        Rules::class,
        FormatRules::class,
        FileRules::class,
        CreditCardRules::class,
    ];

    /**
     * Specifies the views that are used to display the
     * errors.
     *
     * @var array<string, string>
     */
    public array $templates = [
        'list'   => 'CodeIgniter\Validation\Views\list',
        'single' => 'CodeIgniter\Validation\Views\single',
    ];

    // --------------------------------------------------------------------
    // Rules
    // --------------------------------------------------------------------

    // --------------------------------------------------------------------
    // Integrain request rules (one group per form / API call).
    // Use in a controller:  $this->validated($data, 'employeeSave')
    // --------------------------------------------------------------------

    /** Public job application (chat). */
    public array $application = [
        'first_name' => 'required|max_length[60]',
        'last_name'  => 'required|max_length[60]',
        'email'      => 'required|valid_email|max_length[100]',
        'contact_no' => 'required|max_length[20]|regex_match[/^[0-9+\-\s()]{7,20}$/]',
        'opening_id' => 'required|is_natural_no_zero',
        'message'    => 'permit_empty|max_length[2000]',
    ];

    public array $employeeSave = [
        'first_name'        => 'required|max_length[60]',
        'last_name'         => 'required|max_length[60]',
        'middle_name'       => 'permit_empty|max_length[60]',
        'contact_no'        => 'permit_empty|max_length[20]',
        'email'             => 'permit_empty|valid_email|max_length[100]',
        'address'           => 'permit_empty|max_length[255]',
        'date_hired'        => 'required|valid_date[Y-m-d]',
        'daily_rate'        => 'required|decimal|greater_than_equal_to[0]|less_than[100000000]',
        'employment_status' => 'permit_empty|in_list[Active,Inactive,Resigned]',
        'employee_code'     => 'permit_empty|max_length[20]',
        'username'          => 'permit_empty|regex_match[/^[A-Za-z0-9._-]{3,50}$/]',
        'password'          => 'permit_empty|min_length[8]|max_length[72]',
        'account_role'      => 'permit_empty|in_list[Admin,Staff]',
    ];

    public array $attendanceSave = [
        'employee_id'    => 'required|is_natural_no_zero',
        'date'           => 'required|valid_date[Y-m-d]',
        'status'         => 'required|in_list[Present,Late,Half-Day,Absent,On Leave]',
        'time_in'        => 'permit_empty|regex_match[/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/]',
        'time_out'       => 'permit_empty|regex_match[/^([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?$/]',
        'overtime_hours' => 'permit_empty|decimal|greater_than_equal_to[0]|less_than[24]',
        'remarks'        => 'permit_empty|max_length[255]',
    ];

    public array $attendanceClock = ['employee_id' => 'required|is_natural_no_zero', 'action' => 'required|in_list[in,out]'];
    public array $dateOnly        = ['date' => 'required|valid_date[Y-m-d]'];
    public array $dateRange       = ['from' => 'valid_date[Y-m-d]', 'to' => 'valid_date[Y-m-d]'];

    public array $productSave = [
        'name'        => 'required|max_length[100]',
        'category_id' => 'required|is_natural_no_zero',
        'price'       => 'required|decimal|greater_than_equal_to[0]|less_than[100000000]',
        'unit'        => 'required|in_list[kg,sack]',
        'description' => 'permit_empty|max_length[255]',
        'code'        => 'permit_empty|max_length[20]',
    ];

    public array $categorySave = ['name' => 'required|max_length[50]'];

    public array $applicantDecision = [
        'decision'   => 'required|in_list[Approved,Rejected,For Revision]',
        'daily_rate' => 'permit_empty|decimal|greater_than_equal_to[0]|less_than[100000000]',
        'remarks'    => 'permit_empty|max_length[255]',
    ];

    public array $jobOpening = ['description' => 'required|max_length[255]', 'slots' => 'permit_empty|is_natural_no_zero|less_than[1000]'];

    public array $payrollCompute = ['start' => 'required|valid_date[Y-m-d]', 'end' => 'required|valid_date[Y-m-d]', 'employee_id' => 'permit_empty|is_natural_no_zero'];

    public array $payRequestDecision = ['decision' => 'required|in_list[Approved,Rejected]', 'remarks' => 'permit_empty|max_length[255]'];

    public array $adjustmentAdd = [
        'employee_id' => 'required|is_natural_no_zero',
        'type'        => 'required|in_list[Bonus,13th Month Pay]',
        'amount'      => 'permit_empty|decimal|greater_than[0]|less_than[100000000]',
        'remarks'     => 'permit_empty|max_length[255]',
    ];

    public array $payrollSetting = ['key' => 'required|max_length[50]', 'value' => 'required|decimal|greater_than[0]|less_than[100000000]'];

    public array $holidaySave = ['date' => 'required|valid_date[Y-m-d]', 'name' => 'required|max_length[100]', 'type' => 'required|in_list[Regular,Special]'];

    /** Staff: advance or salary-release request. */
    public array $staffRequest = [
        'type'           => 'required|in_list[Paycheck Advance,Salary Request]',
        'amount'         => 'permit_empty|decimal|greater_than[0]|less_than[100000000]',
        'transaction_id' => 'permit_empty|is_natural_no_zero',
        'reason'         => 'required|max_length[255]',
    ];
}
